# Download pp file from MASS and convert to zarr (or NetCDF) files

This folder contains scripts for streamlining data retrieval from MASS and conversion of pp files to NetCDF files. 

This works on JASMIN (and any other system that has access to mass-cli).

This code is hands off and is works in parallel to retrieve pp and convert to NetCDF/zarr files by using scheduling software, `slurm`, so everything runs in parallel on LOTUS compute nodes to speed up conversion.


---

## Usage

Main script, `driver_download_pp_convert.sh` should be run locally on either sci machine of Jasmin. 

This script will submit other scripts slurm's `sbatch` for each stash in a user-defined list, genrally called `processing_queue.csv`. Each slurm array job for each stash is executed in parallel. 

Before executing `driver_download_pp_convert.sh`, user should edit `config.yaml` should be editted to set the job details. 

### Steps for using the script

1. Check prerequisites
    - [ ] Check that there is a conda environment that has iris and yaml. Module jaspy should have this by default.
    - [ ] If execute as batch script, check for batch job compute allocation. See if user has account with QOS short at least. [See manual](https://help.jasmin.ac.uk/docs/batch-computing/how-to-submit-a-job/).

        ``` bash
        user@sci-ph-01$ useraccounts
        # sacctmgr show user fred withassoc format=user,account,qos%-50
        User       Account        QOS
        ---------- -------------- -------------------------------------
            fred  mygws         debug,high,long,short,standard
            fred  orchid        debug,high,long,short,standard
        ```

    - [ ] Check the available stashes in a suite (see below)
    - [ ] Check access to `mass-cli` from current sci machine (see below)

2. Edit or create `processing_queue.csv` file
    - This is for sbatch to parallelize the download for each stash. The file should contain 3 columns. See `processing_queues/processing_queue.csv` for an example.
    - I find it helpful to create the csv in external point-and-click software like Excel/Google Sheets

3. Edit `config.yaml`. This file sets how to run the script for each colum of `processing_queue.csv`.
    - job:
        - `name`: job name for slurm
        - `l_batch`: True/False. Must be True for now as the code only accept sbatch execution
        - `l_download`: True/False. Set to True if downloading the -stash items
        - `l_copy_downloaded`: True/False. Set to True if copying the pp files for each stash items from tmp to other directory.
        - `l_convert`: True/False. Set to True of converting pp to nc or zarr. See convert section below.
        - `l_copy_converted`: True/False. Set to True if copying the converted stash items from tmp to other directory.
    - slurm:
        - `account`: "account". See prerequisite
        - `partition`: "standard". See prerequisite. 
        - `qos`: "short". See prerequisite. 
        - `time`: "4:00:00". See prerequisite. 4 hours is the upper limit for short qos.
        - `memory`: "200000". See prerequisite.
        - `array_range`: "1-6". Set array range in `processing_queue.csv` to execute the code. This does not have to be the whole range of csv and does not have to be continuous. e.g. '1,4,10-13' is acceptable
    - `path`:
        - `tmp_dir`: "/work/scratch-pw2/<USERNAME>" the usual scrath location for a user. Use disk with parallel write access for speed.
        - `downloaded_save_dir`: "/gws/nopw/j04/acsis/vs480/model_output". Optional, for storing pp files long-term 
        - `converted_save_dir`: "/gws/nopw/j04/acsis/vs480/model_output". Optional, for storing converted files long-term
        - `processing_queue`: "./processing_queues/processing_queue.csv" . Relative or absolute path to the `processing_queue.csv`. Name can be changed to submit different queues. Do not forget to set `array_range` accordingly.
    - download:
        - `l_extra_query`: True/False. Set to True if need extra query options. Then specify the query option file below.
        - `max_retries`: 3 optional. Just in case need more than 3 retries for downloading data from MASS
        - `query_options`: "./query_options.txt" optional, for setting extra query options. 
    - convert:
        - `l_use_downloaded_save_dir`: True/False. Optional. For converting from pp files in `downloaded_save_dir` instead of from `tmp_dir`
        - `format`: "nc"/"zarr" case sensitive (untested). only nc is working now


4. Submit the code from the code directory
``` bash
sbatch driver_download_pp_convert.sh
```

This should output log and error file in the current directory.

5. Monitor the job
``` bash
squeue --me
```
This should spawn a master job, then the master job should spawn 
- downloading: one array job for each row in the processing queue csv file, as directed by array_range.
- copying downloaded pp: one array job that depends on the completion of downloading job
- converting: one array job for stash. This then spawn one job for each pp file. There will be a lot of jobs.
- copying converted file: one array job for each stash. This will wait for the conversion to be done.

---
## Useful code snippets

### List all stash id available in a set (a rose suite). 

``` bash
jobid="u-dm931" ## EDIT
for f in $(moo ls moose:crum/$jobid/*pp); do stream=$(echo $f| cut -d/ -f4 | cut -d. -f1) ; moo mdls --attribute=stash $f>> $jobid_$stream ; done
``` 
This lists all stash items in each stream in separate text files.

---
## Known problem

- [ ] This code will always try to check for download pp `max_retries` times. It's probably better to don't try if the download is not corrupted to be a good MASS citizen...
- [ ] working directory in `driver_download_pp_convert.sh` is relative to current directory and is hardcoded. Probably need a better way of doing this.