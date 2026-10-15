#!/usr/bin/env bash

set -euo pipefail

local src="${1:?batch_copy requires a source directory}"
local dest="${2:?batch_copy requires a destination directory}"

echo "Synchronizing files from $src to $dest"

if [[ ! -d "$src" ]]; then
	echo "ERROR: Source directory not found: $src" >&2
	exit 1
fi

mkdir -p "$dest"

# Copy directory contents, preserving metadata and allowing interrupted jobs to resume.
rsync --archive --partial --human-readable --info=stats2 \
	"$src/" "$dest/"

echo "Finished synchronizing files from $src to $dest"
