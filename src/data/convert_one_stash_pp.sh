#!/bin/bash

jobID=$1
stream=$2
stash=$3
download_dir=$4
converted_dir=$5
slurm_download_job_id=$6

# Convert the pp files to netCDF format ---

echo "$jobID; $stream; $stash; conversion to NetCDF; started; $(date)"

# list pp files in the download directory and save to variable
pp_files=$(find "$download_dir" -maxdepth 1 -type f ! -name "*.txt" ! -name "MetOffice*" -printf "%f\n")

# Loop through each pp file and convert it to new format.
# this is done in parallel
for pp_file in $pp_files; do

    # Get the base name of the pp file (without the path)
    base_name=$(basename "$pp_file")
    # Get the file name without the extension
    file="${base_name%.*}"
    # Create the output file name
    converted_file="${file}.$CONVERT_FORMAT"

    pp_file_full="$download_dir/$pp_file"
    converted_file_full="$converted_dir/$converted_file"
    
    # Prepare sbatch command
    sbatch_cmd="sbatch --parsable \
        --job-name=\"convert $base_name\" \
        --partition=\"$SLURM_PARTITION\" \
        --account=\"$SLURM_ACCOUNT\" \
        --qos=\"$SLURM_QOS\" \
        --time=\"$SLURM_TIME\" \
        --mem=\"$SLURM_MEMORY\" \
		--output=\"log/convert_%j.out\" \
		--error=\"log/convert_%j.err\" "

    echo "Converting $pp_file in $download_dir to $CONVERT_FORMAT file" 
    echo "and save to $converted_dir as $converted_file"


    # Add dependency if provided
    if [[ -n "$dependent_id" ]]; then
        sbatch_cmd+=" --dependency=afterok:$dependent_id"
    fi

    sbatch_cmd+=" convert_single_pp.sh $pp_file_full $converted_file_full"

    # Submit the copy job and capture the job ID
    convert_id=$(eval "$sbatch_cmd")

    echo "Converting ID:$convert_id == $pp_file_full to $converted_file_full"
done
