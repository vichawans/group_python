#!/usr/bin/env python3
# filepath: yaml_to_shell.py

import yaml
import sys
import os

def yaml_to_shell_vars(yaml_file, prefix=""):
    """Convert YAML to shell variable exports"""
    try:
        with open(yaml_file, 'r') as f:
            data = yaml.safe_load(f)
        
        def flatten_dict(d, parent_key='', sep='_'):
            items = []
            for k, v in d.items():
                new_key = f"{parent_key}{sep}{k}" if parent_key else k
                if isinstance(v, dict):
                    items.extend(flatten_dict(v, new_key, sep=sep).items())
                elif isinstance(v, list):
                    # Handle arrays
                    for i, item in enumerate(v):
                        items.append((f"{new_key}_{i}", str(item)))
                    items.append((f"{new_key}_count", str(len(v))))
                else:
                    items.append((new_key, str(v)))
            return dict(items)
        
        flat_data = flatten_dict(data)
        
        # Output shell variable exports
        for key, value in flat_data.items():
            # Sanitize key name for shell
            shell_key = f"{prefix}{key}".upper().replace('-', '_')
            # Escape quotes in values
            escaped_value = value.replace('"', '\\"')
            print(f'export {shell_key}="{escaped_value}"')
            
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python yaml_to_shell.py config.yaml [prefix]")
        sys.exit(1)
    
    yaml_file = sys.argv[1]
    prefix = sys.argv[2] + "_" if len(sys.argv) > 2 else ""
    yaml_to_shell_vars(yaml_file, prefix)