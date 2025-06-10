# CAS shared scripts for working with UKESM1 data

This is an effort to document and share scripts with group members. Please make suggestions on how to make this space better and please feel free to fork and add your code and merge back!

This is not to enforce a way of work to anyone. Please feel free to do work your own way or take some parts of the code!

**For new members or people new to working with UKESM1 data**
- There is an example folder for common tasks. It may be a good idea to start there.

## Table of contents
- [How is this repo structured?](#how-is-this-repo-structured)
- [Structure of this repo](#folder-organization)
- How do I do ...? -> Check list of useful tasks in example table of content!
- [Plans](#plans)
- [Useful resources](#other-useful-resources)
- [Change log](#change-log)

## How to use this repo?

The structure of this repo is somewhat based on [cookie-cutter datascience](https://cookiecutter-data-science.drivendata.org/) with a lot of tweaks.

The thinking behind this folder structure is
- Example of tasks are listed in `examples/`. There will be a `README.md` in the folder to provide overview of the example tasks that scripts in this folder cover.
- All reusable functions live in `src/`
- Scripts that are somewhat stable and do specific tasks lives in `script/`. 
    - Scripts in this folder should be self-contained and are likely to call fuctions in `src/` but may just use common libraries such as `iris` or `xarray` to do some tasks.
- Shell scripts that automate scripts or series of tasks lives in `bin/`. 
    - I find that this is the best way to set variables for scripts to be recallable and task-specific.
- Interactive data exploration, especially python notebooks should be in `notebooks/`.
- Machine-specific and project-specific definitions should be in `config/`
- `data/` folder will not be version-controlled and may be used to hold some data.


## Folder organization

    ├── README.md          <- The top-level README (This file)
    |                            
    ├── bin                <- Task-specific scripts. Mostly shell scripts that could be submitted to 
    |                         scheduler such as slurm 
    |                            
    ├── config             <- Folder for any project-level or machine-specific parameters. 
    |                         Any definitions that changes with user or project
    ├── data
    │   ├── external       <- Data from third party sources
    │   ├── interim        <- Intermediate data that has been transformed
    │   ├── processed      <- The final, canonical data sets for analysis
    │   └── raw            <- The original, immutable data dump
    │
    ├── docs               <- Placeholder for any documentation
    │
    ├── examples           <- Placeholder for any example tasks
    │   ├── README.md      <- Table of content of all the examples with description of example task aim
    │
    ├── notebooks          <- Jupyter notebooks. Naming convention is a number (for ordering),
    │                         , '_', and a short `-` delimited description, e.g.
    │                         `1.0_initial-data-exploration.ipynb`
    │
    ├── requirements.txt   <- The requirements file for reproducing the analysis environment, e.g.
    │                         generated with `pip freeze > requirements.txt`
    │
    ├── scripts            <- Task-specific codes that is less exploratory than notebooks.
    │   ├── data_extraction<- Sub-folder for similar type of tasks
    │   ├── data_analysis   
    │   └── visualization   
    │
    └── src                <- Source code for use in this project
        ├── __init__.py    <- Makes src a Python module
        ├── consts.py      <- Immutable constants such as physical and chemical constants
        ├── analysis       <- Scripts for repetitive analysis to be loaded as part of data exploration
        ├── data           <- Scripts to download and convert data from pp to NetCDF
        ├── util           <- Scripts for general utilities, e.g. loading data 
        └── visualization  <- Scripts to create exploratory and results oriented visualizations


## Plans
- Alex has shared his R code base for evaluating UKESM1. It would be extremely helpful to see if the code could be reused for evaluating UKESM1.3 and UKESM2 down the line.
    - Print will create a new github repo for that code and share with the group to start.

## Other useful resources



## Change log

High-leve log. Earliest first.

- 2025-06-10:  Moved all existing scripts to `archive/`. Will slowly look at what is in there.
