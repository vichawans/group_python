#!/bin/bash

pp_file_full=$1
converted_file_full=$2

if [[ "$CONVERT_FORMAT" = "nc" ]]; then
    # need to add the path to this script!
    python3 -u convert_pp_to_nc.py "$pp_file_full" "$converted_file_full"

elif [[ "$CONVERT_FORMAT" = "zarr" ]]; then

    echo 'zarr capability in development. Exit conversion now.'

    # for zarr, need to make new directory for zarr
    # mkdir -p $converted_file_full
    
    # conversion, something along this line
    # python3 -u convert_pp_to_zarr.py "$pp_file_full" "$converted_file_full"
fi