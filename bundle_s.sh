#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

python ./tools/concat.py -s ./plugins/ -o bundle.lua --runtime --embed ./main.lua
