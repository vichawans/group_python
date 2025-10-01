#!/bin/bash

pp_file_full=$1
converted_file_full=$2

if [[ -n $SRC_DATA_DIR ]]; then
	echo "SRC_DATA_DIR file not defined. script may not be located."
fi

# Load the necessary modules and activate the conda environment
module load jaspy
source ~/.bashrc
conda activate "$CONVERT_CONDA_ENV"

if [[ "$CONVERT_FORMAT" = "nc" ]]; then
    # need to add the path to this script!
    python3 -u "$SRC_DATA_DIR"/convert_pp_to_nc.py "$pp_file_full" "$converted_file_full"

elif [[ "$CONVERT_FORMAT" = "zarr" ]]; then

    echo 'zarr capability in development. Exit conversion now.'

    # for zarr, need to make new directory for zarr
    # mkdir -p $converted_file_full
    
    # conversion, something along this line
    # python3 -u convert_pp_to_zarr.py "$pp_file_full" "$converted_file_full"
fi