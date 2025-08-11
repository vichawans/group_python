#!/bin/bash
#SBATCH --job-name=query-control
#SBATCH --account=acsis
#SBATCH --partition=standard # standard or debug
#SBATCH --qos=standard
#SBATCH -o %j.out
#SBATCH -e %j.err
#SBATCH --time=24:00:00
#SBATCH --array=1-5 # edit to match the range in array_stream_stash.txt. This can select only the lines needed
#SBATCH --mem=200000

# driver script to batch download pp files using retrieve_stash.sh

# Usage: sh retrieve_pp_batch.sh

# Set config
tmpdir="/work/scratch-pw2/vs480/"
imax=3
queries=""
processing_queue='./processing_queue.csv'
SLURM_ARRAY_TASK_ID=1


# Extract the stream and stash for the current $SLURM_ARRAY_TASK_ID
jobID=$(awk -F, -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $2}' $processing_queue)
stream=$(awk -F, -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $3}' $processing_queue)
stash=$(awk -F, -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $4}' $processing_queue)


# Internal variables
pp_dir="$tmpdir/pp_files/${jobID}_${stream}_${stash}"

# create pp_dir

# sh retrieve_stash.sh $jobID $stream $stash $pp_dir $imax $queries $>> retrieve_pp_${stash}.log & 
