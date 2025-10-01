#!/bin/bash

# This script reads in configuration from yaml file and sends information to 
# batch download pp and conversion

# USER EDIT
yaml_file='./config.yaml'
proj_dir='/home/users/vs480/scripts/group_python'

# set project paths
src_data_dir="${proj_dir}/src/data"
export UTIL_DIR="${proj_dir}/src/util"
export PATH="$UTIL_DIR:$src_data_dir:$PATH"


# Load variables from yaml file
tmp_env=$(mktemp -p "$TMPDIR" env_XXXXXX.sh)
python3 "${UTIL_DIR}/yaml_to_shell.py" $yaml_file > "$tmp_env"

# shellcheck disable=SC1090
source "$tmp_env"

# This submit N jobs, where N=number of each array job set 
# by slurm_array_range in config.yaml

if [[ "$JOB_L_BATCH" = "True" ]]; then

    sbatch \
        --job-name="$JOB_NAME" \
        --partition="$SLURM_PARTITION" \
        --account="$SLURM_ACCOUNT" \
        --qos="$SLURM_QOS" \
        --time="$SLURM_TIME" \
        --mem="$SLURM_MEMORY" \
        --array="$SLURM_ARRAY_RANGE" \
        batch_process.sh

fi
