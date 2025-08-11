#!/bin/bash
#SBATCH --job-name=u-dm931
#SBATCH --account=mass
#SBATCH --partition=mass # standard or debug
#SBATCH --qos=mass
#SBATCH -o %j.out
#SBATCH -e %j.err
#SBATCH --time=24:00:00
#SBATCH --array=26-32 # edit to match the range in array_stream_stash.txt. This can select only the lines needed
#SBATCH --mem=200000

# batch download pp files using retrieve_stash.sh

# Usage: sh retrieve_pp_batch.sh

# EDIT THE JOB ID AND FOLDER NAME -- use scratch space for speed
jobID="u-bl551"
tmpdir="/work/scratch-pw2/vs480/pp_files/$jobID"

pp_dir="$tmpdir/pp_files"


# Lines below loop over the years and download the data. 
# Edit the stash number and stream name as needed.
# TODO: read array_stream_stash.txt file to get the stream and stash numbers
stream="apm.pp"; stash=34008; sh retrieve_stash.sh $jobID $stream $stash "$pp_dir/${jobID}_${stream}_${stash}" $imax  $>> retrieve_pp_${stash}.log & # H2O2 mmr
