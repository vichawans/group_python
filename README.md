# CAS shared scripts

This is an effort to document and share scripts with group members. Please suggest improving this space, and please feel free to fork, add your code, and merge back. This is not to enforce a way of working on anyone. 

Please feel free to work your way or take some parts of the code!

See the [ukca-eval-python repo](https://github.com/Centre-for-Atmospheric-Science-Cam-Chem/ukesm-eval-python/) for code for evaluating UKESM data against observations. It is also shared and open to contributions! 


**New to this repo?**
- There is an example folder for everyday tasks. It may be a good idea to start there.


## Table of contents
- [How is this repo structured? Why?](#how-is-this-repo-structured)
- [Structure of this repo](#folder-organization)
- [Useful resources](#other-useful-resources)
- [Change log](#change-log)

## How to use this repo?

The structure of this repo is somewhat based on [cookie-cutter datascience](https://cookiecutter-data-science.drivendata.org/), with many tweaks to suit working on different HPCs.

The usage for each folder and the overall structure is explained below. This is not strict, so just add stuff!:
- Examples of tasks are listed in `examples/`. The folder will contain a `README.md` to provide an overview of the example tasks that the scripts in this folder cover.
- All reusable functions live in `src/`
- Scripts that are somewhat stable and do specific tasks live in `script/`. 
    Scripts in this folder should be self-contained and likely to call functions in `src/`, but they may just use common libraries such as `iris` or `xarray` to perform some tasks.
    - It is good practice to set variables so that scripts are recallable, traceable and task-specific.
- Interactive data exploration should be in `notebooks/`, especially Python notebooks.
- Machine-specific and project-specific definitions should be in `config/`
- Get experimental, add your own work in `informal/` to develop, and move codes to the shared spaces when ready.
- The `data/` folder will not be version-controlled and may be used to store some data.


## Folder organisation

    ├── README.md          <- The top-level README (This file)
    |                            
    ├── config             <- Folder for any project-level or machine-specific parameters. 
    |                         Any definitions that change with the user
    ├── data
    │   ├── external       <- Data from third-party sources
    │   ├── interim        <- Intermediate data that has been transformed
    │   ├── processed      <- The final, canonical data sets for analysis
    │   └── raw            <- The original, immutable data dump
    │
    ├── docs               <- Placeholder for any documentation
    │
    ├── examples           <- Placeholder for any example tasks
    │   └── README.md      <- Table of contents of all the examples with description of the example task aim
    │
    ├── informal           <- Scripts that is a work in progress. Please add a subfolder here for your own thing, e.g. vs480 
    │
    ├── notebooks          <- Jupyter notebooks. Naming convention is a number (for ordering),
    │                         , '_', and a short `-` delimited description, e.g.
    │                         `1.0_initial-data-exploration.ipynb`
    │
    ├── requirements.txt   <- The requirements file for reproducing the analysis environment, e.g.
    │                         generated with `pip freeze > requirements.txt`
    │
    ├── scripts            <- Task-specific codes that are less exploratory than notebooks.
    │   ├── data_extraction<- Sub-folder for similar types of tasks
    │   ├── data_analysis   
    │   └── visualization   
    │
    └── src                <- Source code for use in this project
        ├── __init__.py    <- Makes src a Python module
        ├── consts.py      <- Immutable constants such as physical and chemical constants
        ├── analysis       <- Scripts for repetitive analysis to be loaded as part of data exploration
        ├── data           <- Scripts to download and convert data from pp to NetCDF
        ├── util           <- Scripts for general utilities, e.g. loading data 
        └── visualization  <- Scripts to create exploratory and results-oriented visualisations

## Other helpful resources

- See the [ukca-eval-python repo](https://github.com/Centre-for-Atmospheric-Science-Cam-Chem/ukesm-eval-python/) for code for evaluating UKESM data against observations. It is also shared and open to contributions! 
- A lot more useful and group-specific information in the group wiki.
- UKCA training

## Change log

High-level log. Earliest first.

- 2025-06-10:  Moved all existing scripts to `archive/`. Will slowly look at what is in there.
