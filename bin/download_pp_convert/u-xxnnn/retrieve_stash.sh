#!/bin/bash

# This script download pp files from the JASMIN archive that match a given stash number 
# and save to a specified directory. It is designed to be run on mass-cli.
# It uses the moo select to filter out relevant stash. 
# As default, it will try 3 times before exiting.

# This script could be run directly from the command line, or
# as a batch download job from retrieve_pp_batch.sh, or
# as part of a larger workflow from convert_pp_to_nc_batch.sh

# Make sure download_dir exists before running this script

# Edit quer_file.txt as appropriate for the data file being downloaded e.g. include year range
# See https://gws-access.jasmin.ac.uk/public/mohc_shared/moose-user-doc/external_user_guide.html#record-level-retrieval-query-syntax
# Example query file:
# begin
#   stash=38285
#   T1=20180101
#   T2=20181231
# end

# Edit the try loop (imax) to change the number of attempts if needed.

# Usage: sh retrieve_pp.sh $jobID $stream $stash $pp_filename $download_dir $imax (optional)

jobID=$1 # e.g. u-cu594
stream=$2 # e.g. ap4.pp
stash=$3 # e.g. 38285
download_dir=$4 # e.g. /work/scratch-pw2/vs480/pp_files/$jobID/pp_files/${jobID}_${stream}_${stash}

# check if imax is set, if not set it to 3
if [ -z "$imax" ]; then
  imax=3 # Try 3 times
fi

# go to the directory where the data will be downloaded
cd $download_dir

# Log variable information
echo "Current directory = $(pwd)"
echo "Download directory = $download_dir"
echo "Job ID = $jobID"
echo "stream = $stream"
echo "stash = $stash"
echo ""

# create query file 
# See Moose documentation for details on the query file format
# https://gws-access.jasmin.ac.uk/public/mohc_shared/moose-user-doc/external_user_guide.html
# Users are asked not to submit more than 50 moo select commands in parallel. 

echo "Query file="
query_file="query_file.txt"
tee -a $query_file <<EOF
begin
  stash=$stash
end
EOF
echo ""

# load ppfile from moose and save to tmp directory. 
i=1
until [ $i -gt $imax ]; do
  echo "Attemp $i/$imax;"
  echo "  moo select --fill-gaps-and-overwrite-smaller-files $query_file moose:crum/$jobID/$stream ./"
  moo select --fill-gaps-and-overwrite-smaller-files $query_file moose:crum/$jobID/$stream/* ./ 
  ((i++))

  sleep 10s # wait before issuing the next request
done

echo ""
echo "------------------------------------------------"
