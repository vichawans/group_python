"""
Convert pp file to netcdf file in a directory and its subdirectory one by one

Usage: convert_pp_to_zarr.py pp_file_path zarr_file_path
"""

import iris
import xarray as xr
from datetime import datetime
import STASH_fields_defs as def_STASH
import sys

pp_file_path = sys.argv[1]
zarr_file_path = sys.argv[2]


def get_current_time():
    # Print current time
    now = datetime.now()
    current_time = now.strftime("%H:%M:%S")
    return current_time


# read in .pp file
print(f'  Loading file ... {get_current_time()}',end = '')
cubes = iris.load(pp_file_path,callback=def_STASH.UKCA_callback)
print(f' - {get_current_time()}  DONE')

# convert cubes to xarray Dataset
data_vars: dict[str, xr.DataArray] = {}
for cube in cubes:
    da = xr.DataArray.from_iris(cube)
    name = cube.name() or f"var_{len(data_vars)}"
    data_vars[name] = da
ds = xr.Dataset(data_vars)

# Define your desired new chunking pattern
new_chunks = {
    "model_level_number": 10,
    "latitude": 36,
    "longitude": 48
}

# Rechunk the dataset
ds_rechunked = ds.chunk(new_chunks)

# Build encoding dict for all data variables
encoding = {
    var: {
        "chunks": list(new_chunks.values()),
        "compressor": None  # optional: use zarr.Blosc() for compression
    }
    for var in ds.data_vars
}

print(f'  Saving to .zarr ... {get_current_time()}', end = '')
# Save to Zarr
ds_rechunked.to_zarr(zarr_file_path, mode="w", encoding=encoding)
print(f' - {get_current_time()}  DONE')
print(f'  File saved to {zarr_file_path}')
print(f'-----------------------------------------------------------')
