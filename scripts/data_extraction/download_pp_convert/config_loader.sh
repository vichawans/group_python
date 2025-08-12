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
    local temp_vars=$(python3 yaml_to_shell.py "$yaml_file" "$prefix")
    
    # Source the variables
    eval "$temp_vars"
}

# Alternative: Write to temp file and source
load_yaml_config_file() {
    local yaml_file="$1"
    local prefix="${2:-CONFIG}"
    local temp_file=$(mktemp)
    
    python3 yaml_to_shell.py "$yaml_file" "$prefix" > "$temp_file"
    source "$temp_file"
    rm "$temp_file"
}