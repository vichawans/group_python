#!/bin/bash

# copy files over using environment variables
# copy all files in $src directory to $dest directory


src=$1
dest=$2

echo "Copy files from $src to $dest"
mkdir -p "$dest"
cp "$src"/* "$dest"
