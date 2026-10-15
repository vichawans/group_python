#!/bin/bash

jobID=$1
stream=$2
stash=$3
pp_dir=$4
converted_dir=$5
dependent_id=${6:-""}

# Convert the pp files to netCDF format ---

echo "$jobID; $stream; $stash; conversion to NetCDF; started; $(date)"

# List pp files in the extract directory while preserving each filename.
mapfile -t pp_files < <(find "$pp_dir" -maxdepth 1 -type f ! -name "*.txt" ! -name "MetOffice*" -printf "%f\n")

conversion_job_ids=()
declare -A conversion_job_files=()
failed_conversion_files=()

# Loop through each pp file and convert it to new format.
# this is done in parallel
for pp_file in "${pp_files[@]}"; do

    # Get the base name of the pp file (without the path)
    base_name=$(basename "$pp_file")
    # Get the file name without the extension
    file="${base_name%.*}"
    # Create the output file name
    converted_file="${file}.$CONVERT_FORMAT"

    pp_file_full="$pp_dir/$pp_file"
    converted_file_full="$converted_dir/$converted_file"
    
	# submit conversion job to slurm
	if [[ "$JOB_L_BATCH" = "True" ]]; then
		# Prepare sbatch command as an argument array so eval is unnecessary.
		declare -a sbatch_cmd=(
			sbatch
			--parsable
			"--job-name=convert $base_name"
			"--partition=$SLURM_PARTITION"
			"--account=$SLURM_ACCOUNT"
			"--qos=$SLURM_QOS"
			"--time=$SLURM_TIME"
			"--mem=$SLURM_MEMORY"
			--output=log/convert_%j.out
			--error=log/convert_%j.err
		)

		# Add dependency if provided
		if [[ -n "$dependent_id" ]]; then
			sbatch_cmd+=("--dependency=afterok:$dependent_id")
			sbatch_cmd+=(--kill-on-invalid-dep=yes)
		fi

		sbatch_cmd+=(
			"$SRC_DATA_DIR/convert_single_pp.sh"
			"$pp_file_full"
			"$converted_file_full"
		)

		echo "Converting $pp_file in $pp_dir to $CONVERT_FORMAT file" 
		echo "and save to $converted_dir as $converted_file"

		# Submit the conversion job and capture the job ID
		convert_id=$("${sbatch_cmd[@]}")
		conversion_job_ids+=("$convert_id")
		conversion_job_files["$convert_id"]="$pp_file"
	    echo "Converting ID:$convert_id == $pp_file_full to $converted_file_full"

	# Converting interactively in shell
	elif [[ "$JOB_L_BATCH" = "False" ]]; then

		echo "Converting $pp_file in $pp_dir to $CONVERT_FORMAT file" 
		echo "and save to $converted_dir as $converted_file"

		nohup sh convert_single_pp.sh "$pp_file_full" "$converted_file_full" >> log/interactive_convert_"$jobID"_"$stream"_"$stash".log &
	fi
done

if [[ "$JOB_L_BATCH" = "True" && "${#conversion_job_ids[@]}" -gt 0 ]]; then
	echo "Waiting for ${#conversion_job_ids[@]} conversion job(s) to finish."
	conversion_failed=false

	for conversion_id in "${conversion_job_ids[@]}"; do
		while true; do
			conversion_status=$(sacct -X -n -P -j "$conversion_id" \
				--format=State,ExitCode | head -n 1 | tr -d '[:space:]')
			conversion_state="${conversion_status%%|*}"
			conversion_exit_code="${conversion_status#*|}"

			case "$conversion_state|$conversion_exit_code" in
				COMPLETED\|0:0)
					break
				;;
				COMPLETED\|*|FAILED\|*|CANCELLED*\|*|TIMEOUT\|*|OUT_OF_MEMORY\|*|PREEMPTED\|*|NODE_FAIL\|*|BOOT_FAIL\|*|DEADLINE\|*|REVOKED\|*)
					failed_conversion_files+=("${conversion_job_files[$conversion_id]}")
					echo "ERROR: Conversion job $conversion_id failed for file ${conversion_job_files[$conversion_id]} with status $conversion_status." >&2
					conversion_failed=true
					break
				;;
				*)
					sleep 10
				esac
		done
	done

	if [[ "$conversion_failed" = true ]]; then
		echo "ERROR: Conversion failures:" >&2
		for failed_file in "${failed_conversion_files[@]}"; do
			echo "  $failed_file" >&2
		done
		exit 1
	fi
fi
