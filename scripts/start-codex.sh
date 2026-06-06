#!/bin/zsh

set -e

project_dir="${0:A:h:h}"
exec codex -C "$project_dir" "$@"
