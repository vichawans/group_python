#!/usr/bin/env bash

set -euo pipefail

# This script reads in configuration from yaml file and sends information to 
# batch download pp and conversion.
# This script depends on other sources in this repository

# Paths are based on this script, not on the caller's current directory.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/../../.." && pwd -P)"
WORKFLOW_DIR="$SCRIPT_DIR"
LOG_DIR="$WORKFLOW_DIR/log"
CONFIG_FILE="${1:-$WORKFLOW_DIR/config.yaml}"

export SRC_DATA_DIR="$REPO_DIR/src/data"
export UTIL_DIR="$REPO_DIR/src/util"
export WORKFLOW_DIR
export LOG_DIR
# export PATH="$UTIL_DIR:$SRC_DATA_DIR:$PATH"

mkdir -p "$LOG_DIR"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: Configuration file not found: $CONFIG_FILE" >&2
    exit 1
fi

# Create tmp environment and delete upon script exiting 
# whether it succeeds, fails, or exits early. 
tmp_env=$(mktemp "$LOG_DIR/env_XXXXXX.sh")
cleanup() {
    rm -f -- "$tmp_env"
}
trap cleanup EXIT

# Load variables from yaml file
python3 "$UTIL_DIR/yaml_to_shell.py" "$CONFIG_FILE" > "$tmp_env"

# shellcheck disable=SC1090
source "$tmp_env"

resolve_workflow_path() {
    local configured_path="$1"

    if [[ "$configured_path" = /* ]]; then
        printf '%s\n' "$configured_path"
    else
        printf '%s/%s\n' "$WORKFLOW_DIR" "$configured_path"
    fi
}

# Check for processing queue
PATH_PROCESSING_QUEUE="$(resolve_workflow_path "$PATH_PROCESSING_QUEUE")"
export PATH_PROCESSING_QUEUE

if [[ ! -f "$PATH_PROCESSING_QUEUE" ]]; then
    echo "ERROR: Processing queue file not found: $PATH_PROCESSING_QUEUE" >&2
    exit 1
fi

# Check for extra query and if query option is set
if [[ "${EXTRACT_L_EXTRA_QUERY:-False}" == "True" ]]; then
    if [[ -z "${EXTRACT_QUERY_OPTIONS:-}" ]]; then
        echo "ERROR: EXTRACT_QUERY_OPTIONS is required when extra queries are enabled" >&2
        exit 1
    fi

    EXTRACT_QUERY_OPTIONS="$(resolve_workflow_path "$EXTRACT_QUERY_OPTIONS")"
    export EXTRACT_QUERY_OPTIONS

    if [[ ! -f "$EXTRACT_QUERY_OPTIONS" ]]; then
        echo "ERROR: Query options file not found: $EXTRACT_QUERY_OPTIONS" >&2
        exit 1
    fi
fi

# Check for sbatch
if ! command -v sbatch >/dev/null 2>&1 && [[ "${JOB_L_BATCH:-False}" = "True" ]]; then
    echo "ERROR: sbatch is required when job.l_batch is True" >&2
    exit 1
fi

# Check that processing_queue has enough rows for the requested array range.
num_lines=$(wc -l < "$PATH_PROCESSING_QUEUE")
max_array=$(echo "$JOBS_ARRAY_RANGE" | awk -F'[-,]' '{print $NF}')

if ! [[ "$max_array" =~ ^[0-9]+$ ]]; then
    echo "ERROR: Invalid jobs.array_range: $JOBS_ARRAY_RANGE" >&2
    exit 1
fi

if [[ "$num_lines" -lt "$max_array" ]]; then
    echo "ERROR: Processing queue has $num_lines lines but array_range requests up to $max_array" >&2
    echo "       Update JOBS_ARRAY_RANGE in config.yaml to match processing_queue.csv"
    exit 1
fi

echo "Processing queue validation: PASSED"
echo "  Workflow: $WORKFLOW_DIR"
echo "  Config: $CONFIG_FILE"
echo "  Data scripts: $SRC_DATA_DIR"
echo "  File: $PATH_PROCESSING_QUEUE"
echo "  Total lines: $num_lines"
echo "  Array range: $JOBS_ARRAY_RANGE"
echo ""

# check if EXTRACT_DRY_RUN is set. If set, just exit as not actually running anything. 
if [[ "${EXTRACT_DRY_RUN:-False}" = "True" ]]; then
    echo "Dry run requested; no jobs submitted."
    exit 0
fi

# This submit N jobs, where N=number of each array job set 
# by JOBS_ARRAY_RANGE in config.yaml

if [[ "$JOB_L_BATCH" = "True" ]]; then
    sbatch \
        --job-name="$JOB_NAME" \
        --partition="$SLURM_PARTITION" \
        --account="$SLURM_ACCOUNT" \
        --qos="$SLURM_QOS" \
        --time="$SLURM_TIME" \
        --mem="$SLURM_MEMORY" \
        --array="$JOBS_ARRAY_RANGE" \
        --chdir="$WORKFLOW_DIR" \
        --output="$LOG_DIR/driver_%j.out" \
        --error="$LOG_DIR/driver_%j.err" \
        "$SRC_DATA_DIR/batch_process.sh"

	echo "Execute command 'squeue --me' to monitor all the submitted job."
	
else
	echo "interactive shell session for extraction from MASS only"
	max_jobs=6
	
    bash "$WORKFLOW_DIR/submit_to_mass-cli.sh" "$max_jobs" "$JOBS_ARRAY_RANGE"
fi
