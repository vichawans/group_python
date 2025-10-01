#!/bin/bash
#SBATCH --job-name=dl_pp
#SBATCH --account=acsis
#SBATCH --partition=debug # standard or debug
#SBATCH --qos=debug
#SBATCH -o %j.out
#SBATCH -e %j.err
#SBATCH --time=1:00:00
#SBATCH --array=1-4 # edit to match the range in array_stream_stash.txt. This can select only the lines needed
#SBATCH --mem=200000

# driver script to batch download pp files using retrieve_stash.sh
# Note that command-line arguments to sbatch (like --job-name, --partition, etc.) 
# override the preceeding #SBATCH directives in this script.

# Usage: sh retrieve_pp_batch.sh

### DEFINE FUNCTIONS ##################################################################

batch_retrieve_pp () {

# Create download_dir and parent directories if they don't exist
mkdir -p "$download_dir"

# Verify directory was created successfully
if [[ ! -d "$download_dir" ]]; then
    echo "Error: Failed to create directory $download_dir" >&2
    exit 1
fi

echo "Created/verified directory: $download_dir"

# submit to mass queue
# SLURM job submission using config
slurm_download_job_id=$(sbatch --parsable \
       --job-name="$jobID $stash pp" \
       --partition="mass" \
       --account="mass" \
       --qos="mass" \
       retrieve_stash.sh "$jobID" \
       "$stream" "$stash" "$download_dir" \
       "$DOWNLOAD_MAX_RETRIES" \
       "$DOWNLOAD_QUERY_OPTIONS" )

echo "Submitted MASS retrieval job with job ID: $slurm_download_job_id"
echo "jobID=$jobID; stream=$stream; stash=$stash"

return "$slurm_download_job_id"
}

batch_convert_pp () {
    dependent_id=$1

    echo "Parallel convert files"

    # Prepare sbatch command
    local sbatch_cmd="sbatch --parsable \
        --job-name=\"pp2$CONVERT_FORMAT dep:$dependent_id\" \
        --partition=\"$SLURM_PARTITION\" \
        --account=\"$SLURM_ACCOUNT\" \
        --qos=\"$SLURM_QOS\" \
        --time=\"$SLURM_TIME\" \
        --mem=\"$SLURM_MEMORY\""

    # Add dependency if provided
    if [[ -n "$dependent_id" ]]; then
        sbatch_cmd+=" --dependency=afterok:$dependent_id"
    fi

    sbatch_cmd+=" convert_one_stash_pp.sh \"$jobID\" \
        \"$stream\" \
        \"$stash\" \
        \"$download_dir\" \
        \"$convert_dir\" \
        \"$slurm_download_job_id\""

    # Submit the copy job and capture the job ID
    slurm_convert_job_id=$(eval "$sbatch_cmd")
    echo "Submitted convert job with job ID: $slurm_convert_job_id"
    if [[ -n "$dependent_id" ]]; then
        echo "Job will begin after $dependent_id"
    fi
    echo ""
    return 0
}

batch_copy () {
    src=$1
    dest=$2
    dependent_id=$3

    echo "Copy files from $src to $dest"
    # Prepare sbatch command
    local sbatch_cmd="sbatch --parsable \
        --job-name=\"cp dep:$dependent_id\" \
        --partition=\"$SLURM_PARTITION\" \
        --account=\"$SLURM_ACCOUNT\" \
        --qos=\"$SLURM_QOS\" \
        --time=\"$SLURM_TIME\" \
        --mem=\"$SLURM_MEMORY\""

    # Add dependency if provided
    if [[ -n "$dependent_id" ]]; then
        sbatch_cmd+=" --dependency=afterok:$dependent_id"
    fi

    sbatch_cmd+=" copy_files.sh \"$src\" \"$dest\""

    # Submit the copy job and capture the job ID
    copy_id=$(eval "$sbatch_cmd")

    echo "Submitted copy job with job ID: $copy_id"
    if [[ -n "$dependent_id" ]]; then
        echo "Copy job will begin after $dependent_id"
    fi

    echo ""
    return 0
}


### SET VARIABLES #################################################################

processing_queue="$PATH_PROCESSING_QUEUE"

# Extract the stream and stash for the current $SLURM_ARRAY_TASK_ID
jobID=$(grep "^$SLURM_ARRAY_TASK_ID," "$processing_queue" | head -n1 | cut -d',' -f2 | tr -d '\r')
stream=$(grep "^$SLURM_ARRAY_TASK_ID," "$processing_queue" | head -n1 | cut -d',' -f3 | tr -d '\r')
stash=$(grep "^$SLURM_ARRAY_TASK_ID," "$processing_queue" | head -n1 | cut -d',' -f4 | tr -d '\r')


# Internal variables
# set download dir to tmp dir if downloading data or if copying data
if [[ "$JOB_L_DOWNLOAD" = "True" || "$JOB_COPY_DOWNLOADED" = "True" ]]; then
    download_dir="$PATH_TMP_DIR/pp_files/${jobID}/${stream}_${stash}"
    mkdir -p "$download_dir"
fi

# set download_dir and convert_dir if converting from pp
if [[ "$JOB_L_CONVERT" = "True" ]]; then
    convert_dir="$PATH_TMP_DIR/${CONVERT_FORMAT}_files/${jobID}/${stream}_${stash}"
    mkdir -p "$convert_dir"

    # pp data has been downloaded and is in tmp
    if [[ "$JOB_L_DOWNLOAD" = "False" &&  $CONVERT_L_USE_DOWNLOADED_SAVE_DIR = "False" ]]; then
       download_dir="$PATH_TMP_DIR/pp_files/${jobID}/${stream}_${stash}"
    
    # pp data has been downloaded and saved to DOWNLOADED_DATA_DIR
    elif [[ "$JOB_L_DOWNLOAD" = "False" && $CONVERT_L_USE_DOWNLOADED_SAVE_DIR = "True" ]]; then
        download_dir="$PATH_DOWNLOADED_SAVE_DIR/pp_files/${jobID}/${stream}_${stash}"
    fi
fi

# Set download save dir
if [[ "$JOB_L_COPY_DOWNLOADED" = "True" && -n "$PATH_DOWNLOADED_SAVE_DIR" ]]; then
    downloaded_save_dir_full=$PATH_DOWNLOADED_SAVE_DIR/pp_files/${jobID}/${stream}_${stash}
    copy_downloaded=True

elif [[ "$JOB_L_COPY_DOWNLOADED" = "True" && -z "$PATH_DOWNLOADED_SAVE_DIR" ]]; then
    echo "Error. Set to copy downloaded files but"
    echo 'downloaded_save_dir is not set in config.yaml. Will not copy pp files'
    copy_downloaded=False

else
    copy_downloaded=False
fi

# Set converted save dir
if [[ "$JOB_L_COPY_CONVERTED" = "True" && -n "$PATH_CONVERTED_SAVE_DIR" ]]; then
    converted_save_dir_full=$PATH_CONVERTED_SAVE_DIR/${CONVERT_FORMAT}_files/${jobID}/${stream}_${stash}
    copy_converted=True

elif [[ "$JOB_L_COPY_CONVERTED" = "True" && -z "$PATH_CONVERTED_SAVE_DIR" ]]; then
    echo "Error. Set to copy converted files but"
    echo 'converted_save_dir is not set in config.yaml. Will not copy converted files'
    copy_converted=False

else
    copy_converted=False
fi


### EXECUTION ##################################################################

echo "Start: $jobID $stream $stash"


# If download only and not convert
if [[ "$JOB_L_DOWNLOAD" = "True" ]]; then

    echo "Download $jobID $stream $stash"
    echo ""

	batch_retrieve_pp

    # Copy pp files after download
    if [[ $copy_downloaded = 'True' ]]; then
        batch_copy "$download_dir" "$downloaded_save_dir_full" "$slurm_download_job_id"
    fi

fi

# If download then convert
if [[ "$JOB_L_DOWNLOAD" = "True" && "$JOB_L_CONVERT" = "True" ]]; then

    batch_convert_pp "$slurm_download_job_id"
	echo "Started downloading with slurm_convert_job_id=$slurm_convert_job_id"
	echo "This job depends on slurm_download_job_id=$slurm_download_job_id"
    # Copy pp files after download

    if [[ $copy_converted = 'True' ]]; then
        batch_copy "$convert_dir" "$converted_save_dir_full" "$slurm_convert_job_id"
    fi

# Just convert
else [[ "$JOB_L_DOWNLOAD" = "False" && "$JOB_L_CONVERT" = "True" ]]

    # This will convert each pp file in $download_dir 
    batch_convert_pp
	echo "Started downloading with slurm_convert_job_id=$slurm_convert_job_id"

    if [[ $copy_converted = 'True' ]]; then
        batch_copy "$convert_dir" "$converted_save_dir_full" "$slurm_convert_job_id"
    fi
fi

# If copying downloaded files without actually downloading files
if [[ "$JOB_L_DOWNLOAD" = "False" && $copy_downloaded = 'True' ]]; then
    batch_copy "$download_dir" "$downloaded_save_dir_full"
fi

# If copying converted files without actually downloading files
if [[  "$JOB_L_CONVERT" = "False" && $copy_converted = 'True' ]]; then
    batch_copy "$convert_dir" "$converted_save_dir_full"
fi

echo "Finish: $jobID $stream $stash"