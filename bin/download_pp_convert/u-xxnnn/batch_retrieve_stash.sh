#!/bin/bash

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
