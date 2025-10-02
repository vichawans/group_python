#!/bin/bash

slurm_download_job_id=$(sbatch --parsable \
       --job-name="pp" \
       --partition="mass" \
       --account="mass" \
       --qos="mass" \
        test_moo.sh
)
		
echo "Hi from $0 with slurm_download_job_id=$slurm_download_job_id"