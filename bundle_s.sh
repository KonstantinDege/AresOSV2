#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

python ./tools/concat.py -s ./base_plugins/ -o bundle.lua --runtime --prefix="plugins." --embed ./main.lua
