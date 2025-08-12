#!/bin/bash
#SBATCH --job-name=dl_pp
#SBATCH --account=acsis
#SBATCH --partition=debug # standard or debug
#SBATCH --qos=debug
#SBATCH -o %j.out
#SBATCH -e %j.err
#SBATCH --time=1:00:00
#SBATCH --array=1-3 # edit to match the range in array_stream_stash.txt. This can select only the lines needed
#SBATCH --mem=200000

# driver script to batch download pp files using retrieve_stash.sh

# Usage: sh retrieve_pp_batch.sh

# Set config
tmpdir="/work/scratch-pw2/vs480/"
imax=3
queries=""
processing_queue='./processing_queue.csv'

# Get current task ID
TASK_ID=$SLURM_ARRAY_TASK_ID

# Extract the stream and stash for the current $SLURM_ARRAY_TASK_ID
jobID=$(awk -F, -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $2}' $processing_queue)
stream=$(awk -F, -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $3}' $processing_queue)
stash=$(awk -F, -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $4}' $processing_queue)


# Internal variables
pp_dir="$tmpdir/pp_files/${jobID}_${stream}_${stash}"

# Create pp_dir and parent directories if they don't exist
mkdir -p "$pp_dir"

# Verify directory was created successfully
if [[ ! -d "$pp_dir" ]]; then
    echo "Error: Failed to create directory $pp_dir" >&2
    exit 1
fi

echo "Created/verified directory: $pp_dir"

# submit to mass queue
# sh retrieve_stash.sh $jobID $stream $stash $pp_dir $imax $queries $>> retrieve_pp_${stash}.log & 
# SLURM job submission using config
SLURM_RETRIEVE_ID=$(sbatch --parsable \
       --job-name="$APP_JOB_NAME" \
       --account="mass" \
       --partition="mass" \
       --qos="mass" \
       retrieve_stash.sh)

echo "Submitted MASS retrieval job for $SLURM_ARRAY_TASK_ID with job ID: $SLURM_RETRIEVE_ID"