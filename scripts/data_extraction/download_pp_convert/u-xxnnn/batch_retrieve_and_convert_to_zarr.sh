#!/bin/bash
#SBATCH --job-name=u-dm931
#SBATCH --account=acsis
#SBATCH --partition=standard # standard or debug
#SBATCH --qos=high
#SBATCH -o %j.out
#SBATCH -e %j.err
#SBATCH --time=24:00:00
#SBATCH --array=26-32 # edit to match the range in array_stream_stash.txt. This can select only the lines needed
#SBATCH --mem=200000

# ------------ DESCRIPTION ----------------

# This script is used to download pp files from the JASMIN archive and convert them to zarr format.
# It is designed to be run on the JASMIN cluster and uses the Jaspy module to load the necessary environment.

# For slurm array jobs:
# EDIT SBATCH swithces to match your job requirements.
# !!! EDIT --array to match the items to extract in array_stream_stash.txt

# Otherwise, set stream and stash manually and this script can be run as a normal bash script.

# By Print/Vichawan S., 2025-05-13 (vs480)

# ------------ USER DEFINED VARIABLES ----------------

jobID='u-dm931' # e.g. u-cf123
array_stream_stash="./array_stream_stash.txt"

conda_env="cmip6-env" # conda environment to use
tmpdir="/work/scratch-pw2/vs480/$jobID"
outdir="/gws/nopw/j04/acsis/vs480/model_output/$jobID"
imax=3 # As default, it will try to download each stash 3 times before continuing.

# SSH public key for authentication
pubkey=$(cat ~/.ssh/id_ed25519_login.pub)

# ------------ END USER DEFINED VARIABLES ------------

# Replace /path/to/public_key.pub with your actual public key file
grep -qxF "$pubkey" ~/.ssh/authorized_keys || echo "$pubkey" >> ~/.ssh/authorized_keys


# Extract the stream and stash for the current $SLURM_ARRAY_TASK_ID
stream=$(awk -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $2}' $array_stream_stash)
stash=$(awk -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $3}' $array_stream_stash)

# start of array job
echo "This is array task ${SLURM_ARRAY_TASK_ID}, the stream is ${stream} and the stash is ${stash}."

# Load the necessary modules and activate the conda environment
module load jaspy
source ~/.bashrc
conda activate $conda_env

# Create the output directory if it doesn't exist
mkdir -p $tmpdir
mkdir -p $outdir

pp_dir="$tmpdir/pp_files"
mkdir -p $pp_dir
zarr_dir="$tmpdir/zarr_files"
mkdir -p $zarr_dir

folder_name="${jobID}_${stream}_${stash}"

# Download the pp files from each stash and stream ---

# Create a directory for the downloaded files
pp_out_dir="$pp_dir/$folder_name"
mkdir -p $pp_out_dir

# Download the pp files using retrieve_stash.sh
# Try to download each stash $imax times.
# script should run in mass-cli
echo "$jobID; $stream; $stash; pp download; started; $(date)"
ssh jasmin-mass 'bash -s' $jobID $stream $stash $pp_out_dir $imax <retrieve_stash.sh >>${folder_name}.log
echo "$jobID; $stream; $stash; pp download; done; $(date)"

# Convert the pp files to zarr format ---

# Create a directory for the converted zarr files
zarr_out_dir="$zarr_dir/$folder_name"
mkdir -p $zarr_out_dir

echo "$jobID; $stream; $stash; conversion to zarr; started; $(date)"

# list files in the download directory and save to variable
pp_files=$(ls -I "*.txt" -I "MetOffice*" $pp_out_dir)

# Loop through each pp file and convert it to zarr format.
# this is done in parallel
for pp_file in $pp_files; do
    # Get the base name of the pp file (without the path)
    base_name=$(basename $pp_file)
    # Get the file name without the extension
    file="${base_name%.*}"
    # Create the output zarr file name
    zarr_file="${file}.zarr"
    # Create the zarr file in the output directory
    mkdir -p $zarr_out_dir/$zarr_file

    echo "Converting $pp_file in $pp_out_dir to zarr file and save to $zarr_dir as $zarr_file" &>>${folder_name}_${file}.log &
    python3 -u convert_pp_to_zarr.py "$pp_out_dir/$pp_file" "$zarr_out_dir/$zarr_file" &>>${folder_name}_${file}.log &
done

wait
echo "$jobID; $stream; $stash; conversion to zarr; done; $(date)"

# Copy the zarr files to the output directory ---
echo "$jobID; $stream; $stash; copy zarr to outdir; started; $(date)"

rsync -prtu $zarr_out_dir $outdir >>${folder_name}.log

echo "$jobID; $stream; $stash; copy zarr to outdir; done; $(date)"
