#!/bin/bash

# This script reads in configuration from yaml file and submits batch 
# STASH extraction jobs for PP files

# USER EDIT
export proj_dir='../../..'
export cwd=$(pwd)
export yaml_file="$cwd/config.yaml"

# set project paths. This script depends on other code in src/data and src/util in this repo
export SRC_DATA_DIR="${proj_dir}/src/data"
export UTIL_DIR="${proj_dir}/src/util"
export PATH="$UTIL_DIR:$SRC_DATA_DIR:$PATH"

# Set tmpdir to log, in case this is not set
if [[ -z $TMPDIR ]]; then
    TMPDIR='./log/'
fi

tmp_env=$(mktemp -p "$TMPDIR" env_XXXXXX.sh)

# Load variables from yaml file
python3 "${UTIL_DIR}/yaml_to_shell.py" "$yaml_file" > "$tmp_env"

# shellcheck disable=SC1090
source "$tmp_env"

# Create log directory if it doesn't exist
mkdir -p "./log"

# Submit batch array jobs if l_batch is True
if [[ "$JOB_L_BATCH" = "True" ]] && [[ "$JOB_L_EXTRACT" = "True" ]]; then

    sbatch \
        --job-name="$JOB_NAME" \
        --partition="$SLURM_PARTITION" \
        --account="$SLURM_ACCOUNT" \
        --qos="$SLURM_QOS" \
        --time="$SLURM_TIME" \
        --mem="$SLURM_MEMORY" \
        --array="$SLURM_ARRAY_RANGE" \
		--output="log/extract_%j.out" \
		--error="log/extract_%j.err" \
        "./extract_batch.sh"

    echo "SLURM extraction jobs submitted."
	echo "Execute command 'squeue --me' to monitor all submitted jobs."

# Run locally if l_batch is False but l_extract is True
elif [[ "$JOB_L_EXTRACT" = "True" ]]; then

    echo "Running extraction locally (l_batch=False)"
    echo "Not yet implemented"

else
    echo "Extraction disabled (l_extract=False)"
    exit 0
fi

