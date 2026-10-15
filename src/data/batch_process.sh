#!/bin/bash
#SBATCH --job-name=MASS_extract
#SBATCH --account=acsis
#SBATCH --partition=debug # standard or debug
#SBATCH --qos=debug
#SBATCH -o %j.out
#SBATCH -e %j.err
#SBATCH --time=1:00:00
#SBATCH --array=1-4 # edit to match the range in array_stream_stash.txt. This can select only the lines needed
#SBATCH --mem=200000

# driver script to batch extract pp files using extract_stash.sh
# Note that command-line arguments to sbatch (like --job-name, --partition, etc.) 
# override the preceeding #SBATCH directives in this script.

# Usage: sbatch retrieve_pp_batch.sh

set -euo pipefail

# set paths if not already set
DATA_DIR=${SRC_DATA_DIR:-"$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"}
WORKFLOW_DIR=${WORKFLOW_DIR:-"$(cd -- "$DATA_DIR/../../scripts/data_extraction/extract_pp_from_mass_convert" && pwd -P)"}
LOG_DIR=${LOG_DIR:-"$WORKFLOW_DIR/log"}

mkdir -p "$LOG_DIR"

### DEFINE FUNCTIONS ##################################################################

batch_extract_pp () {

# Create tmp_pp_dir and parent directories if they don't exist
mkdir -p "$tmp_pp_dir"

# Verify directory was created successfully
if [[ ! -d "$tmp_pp_dir" ]]; then
    echo "Error: Failed to create directory $tmp_pp_dir" >&2
    exit 1
fi

echo "Created/verified directory: $tmp_pp_dir"

# submit to mass queue
# SLURM job submission using config
slurm_extract_job_id=$(sbatch --parsable \
        --job-name="$jobID-$stash-pp" \
        --partition="mass" \
        --account="mass" \
        --qos="mass" \
		--time="$EXTRACT_WALLTIME" \
		--mem=94000M \
        --chdir="$WORKFLOW_DIR" \
        --output="$LOG_DIR/extract_%x_%j.out" \
        --error="$LOG_DIR/extract_%x_%j.err" \
        "$DATA_DIR/extract_stash.sh" "$jobID" \
        "$stream" "$stash" "$tmp_pp_dir" \
        "$EXTRACT_MAX_RETRIES" \
        "$EXTRACT_QUERY_OPTIONS" )

echo "Submitted MASS extraction job with job ID: $slurm_extract_job_id"
echo "jobID=$jobID; stream=$stream; stash=$stash"

return 0 
}

batch_convert_pp () {
    local dependent_id="${1:-}"

    echo "Parallel convert files"

    # Prepare sbatch command as an argument array so eval is unnecessary.
    local -a sbatch_cmd=(
        sbatch
        --parsable
        "--job-name=pp2$CONVERT_FORMAT dep:$dependent_id"
        "--partition=$SLURM_PARTITION"
        "--account=$SLURM_ACCOUNT"
        "--qos=$SLURM_QOS"
        "--time=$SLURM_TIME"
        "--mem=$SLURM_MEMORY"
        "--output=$LOG_DIR/convert_%j.out"
        "--error=$LOG_DIR/convert_%j.err"
    )

    # Add dependency if provided
    if [[ -n "$dependent_id" ]]; then
        sbatch_cmd+=(
            "--dependency=afterok:$dependent_id"
            "--kill-on-invalid-dep=yes"
        )
    fi

    sbatch_cmd+=(
        "$DATA_DIR/convert_one_stash_pp.sh"
        "$jobID"
        "$stream"
        "$stash"
        "$tmp_pp_dir"
        "$convert_dir"
        "$dependent_id"
    )

    # Submit the conversion job and capture the job ID
    slurm_convert_job_id=$("${sbatch_cmd[@]}")
    echo "Submitted convert job with job ID: $slurm_convert_job_id"
    if [[ -n "$dependent_id" ]]; then
        echo "Job will begin after $dependent_id"
    fi
    echo ""
    return 0
}

batch_copy () {
	# copy all files in $src directory to $dest directory
    local src=$1
    local dest=$2
    local dependent_id="${3:-}"

    echo "Copy files from $src to $dest"
    # Prepare sbatch command as an argument array so eval is unnecessary.
    local -a sbatch_cmd=(
        sbatch
        --parsable
        "--job-name=cp dep:$dependent_id"
        "--partition=$SLURM_PARTITION"
        "--account=$SLURM_ACCOUNT"
        "--qos=$SLURM_QOS"
        "--time=$SLURM_TIME"
        "--mem=$SLURM_MEMORY"
        "--chdir=$WORKFLOW_DIR"
        "--output=$LOG_DIR/cp_%j.out"
        "--error=$LOG_DIR/cp_%j.err"
    )

    # Add dependency if provided
    if [[ -n "$dependent_id" ]]; then
        sbatch_cmd+=(
            "--dependency=afterok:$dependent_id"
            --kill-on-invalid-dep=yes
        )
    fi

    sbatch_cmd+=(
        "$DATA_DIR/copy_files.sh"
        "$src"
        "$dest"
    )

    # Submit the copy job and capture the job ID
    copy_id=$("${sbatch_cmd[@]}")

    echo "Submitted copy job with job ID: $copy_id"
    if [[ -n "$dependent_id" ]]; then
        echo "Job will begin after $dependent_id"
    fi

    echo ""
    return 0
}


### SET VARIABLES #################################################################

processing_queue="$PATH_PROCESSING_QUEUE"

# Extract the complete queue row once for the current array task.
queue_row=$(awk -F',' -v task_id="$SLURM_ARRAY_TASK_ID" \
    'NR > 1 && $1 == task_id { print; exit }' "$processing_queue")
if [[ -z "$queue_row" ]]; then
    echo "ERROR: No processing queue row for array task $SLURM_ARRAY_TASK_ID" >&2
    exit 1
fi

queue_row="${queue_row%$'\r'}"
IFS=, read -r _queue_task jobID stream stash _queue_label <<< "$queue_row"


# Internal variables
# set extract dir to tmp dir if extracting data or if copying data
if [[ "$JOB_L_EXTRACT" = "True" || "$JOB_L_COPY_EXTRACTED" = "True" ]]; then
    tmp_pp_dir="$PATH_TMP_DIR/pp_files/${jobID}/${stream}_${stash}"
    mkdir -p "$tmp_pp_dir"
fi

# set tmp_pp_dir and convert_dir if converting from pp
if [[ "$JOB_L_CONVERT" = "True"  || "$JOB_L_COPY_CONVERTED" = "True"  ]]; then
    convert_dir="$PATH_TMP_DIR/${CONVERT_FORMAT}_files/${jobID}/${stream}_${stash}"
    mkdir -p "$convert_dir"

    # pp data has been extracted and is in tmp
    if [[ "$JOB_L_EXTRACT" = "False" &&  $CONVERT_L_USE_EXTRACTED_SAVE_DIR = "False" ]]; then
       tmp_pp_dir="$PATH_TMP_DIR/pp_files/${jobID}/${stream}_${stash}"
    
    # pp data has been extracted and saved to EXTRACTED_DATA_DIR
    elif [[ "$JOB_L_EXTRACT" = "False" && $CONVERT_L_USE_EXTRACTED_SAVE_DIR = "True" ]]; then
        tmp_pp_dir="$PATH_EXTRACTED_SAVE_DIR/pp_files/${jobID}/${stream}_${stash}"
    fi
fi

# Set extract save dir
if [[ "$JOB_L_COPY_EXTRACTED" = "True" && -n "$PATH_EXTRACTED_SAVE_DIR" ]]; then
    extracted_save_dir_full=$PATH_EXTRACTED_SAVE_DIR/pp_files/${jobID}/${stream}_${stash}
    copy_extracted=True

elif [[ "$JOB_L_COPY_EXTRACTED" = "True" && -z "$PATH_EXTRACTED_SAVE_DIR" ]]; then
    echo "Error. Set to copy extracted files but"
    echo 'extracted_save_dir is not set in config.yaml. Will not copy pp files'
    copy_extracted=False

else
    copy_extracted=False
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

echo "Start submission: $jobID $stream $stash"
echo ""

# If extract only and not convert
if [[ "$JOB_L_EXTRACT" = "True" ]]; then
	batch_extract_pp

	echo "Submitted extracting with slurm_extract_job_id=$slurm_extract_job_id"
    echo ""
fi

# Copy pp files after extract
if [[ "$JOB_L_EXTRACT" = "True" && $copy_extracted = 'True' ]]; then
	batch_copy "$tmp_pp_dir" "$extracted_save_dir_full" "$slurm_extract_job_id"
fi

# If copying extracted files without actually extracting files
if [[ "$JOB_L_EXTRACT" = "False" && $copy_extracted = 'True' ]]; then
    batch_copy "$tmp_pp_dir" "$extracted_save_dir_full"
fi


# If extract then convert
if [[ "$JOB_L_EXTRACT" = "True" && "$JOB_L_CONVERT" = "True" ]]; then

    batch_convert_pp "$slurm_extract_job_id"
	echo "Submitted converting with slurm_convert_job_id=$slurm_convert_job_id"
	echo "This job depends on slurm_extract_job_id=$slurm_extract_job_id"
    echo ""

fi

# Just convert
if [[ "$JOB_L_EXTRACT" = "False" && "$JOB_L_CONVERT" = "True" ]]; then

    batch_convert_pp
	echo "Submitted converting with slurm_convert_job_id=$slurm_convert_job_id"
    echo ""

fi

# If copying converted files after conversion
if [[ "$JOB_L_CONVERT" = "True" &&  $copy_converted = 'True' ]]; then
	batch_copy "$convert_dir" "$converted_save_dir_full" "$slurm_convert_job_id"
fi

# If copying converted files without actually extracting files
if [[  "$JOB_L_CONVERT" = "False" && $copy_converted = 'True' ]]; then
    batch_copy "$convert_dir" "$converted_save_dir_full"
fi

echo "Finished submission: $jobID $stream $stash"
echo ""
