#!/bin/bash

# copy files over using environment variables

src=$1
dest=$2

echo "Copy files from $src to $dest"
cp "$src" "$dest"
