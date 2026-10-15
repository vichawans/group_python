#!/bin/bash

pp_file_full=$1
converted_file_full=$2

if [[ -z "${SRC_DATA_DIR:-}" ]]; then
    echo "SRC_DATA_DIR is not defined; cannot locate conversion scripts." >&2
    exit 1
fi

# Load the necessary modules and activate the conda environment
module load jaspy

if [[ "$CONVERT_FORMAT" = "nc" ]]; then
    if ! python3 -u "$SRC_DATA_DIR"/convert_pp_to_nc.py "$pp_file_full" "$converted_file_full"; then
        echo "ERROR: Conversion failed for $pp_file_full" >&2
        exit 1
    fi

    if ! python3 - "$converted_file_full" <<'PY'
import sys

import iris

netcdf_path = sys.argv[1]
try:
    cubes = iris.load(netcdf_path)
except Exception as error:
    print(f"ERROR: NetCDF validation failed for {netcdf_path}: {error}", file=sys.stderr)
    raise SystemExit(1)

if not cubes:
    print(f"ERROR: NetCDF validation found no readable cubes in {netcdf_path}", file=sys.stderr)
    raise SystemExit(1)

print(f"NetCDF validation passed: {netcdf_path} ({len(cubes)} cube(s))")
PY
    then
        exit 1
    fi

elif [[ "$CONVERT_FORMAT" = "zarr" ]]; then

    echo 'zarr capability in development. Exit conversion now.'

    # for zarr, need to make new directory for zarr
    # mkdir -p $converted_file_full
    
    # conversion, something along this line
    # python3 -u convert_pp_to_zarr.py "$pp_file_full" "$converted_file_full"
fi