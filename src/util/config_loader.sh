#!/bin/bash

load_yaml_config() {
    local yaml_file="$1"
    local prefix="${2:-CONFIG}"
    
    # Check if file exists
    if [[ ! -f "$yaml_file" ]]; then
        echo "Error: YAML file '$yaml_file' not found" >&2
        return 1
    fi
    
    # Use Python to convert YAML to shell variables
    local temp_vars
    temp_vars=$(python3 yaml_to_shell.py "$yaml_file" "$prefix")
    
    # Source the variables
    eval "$temp_vars"
}