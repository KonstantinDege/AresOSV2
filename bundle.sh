#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

message="${1:-Update bundle}"

python ./tools/concat.py -s ./plugins/ -o bundle.lua --runtime --minify --embed ./main.lua

git add .
git commit -a -m "$message"
git push
