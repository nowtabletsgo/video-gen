#!/usr/bin/env bash
set -euo pipefail

COMFY_DIR="/workspace/ComfyUI"
REPO_DIR="/workspace/repos/video-gen"

echo "== pull repo =="
cd "$REPO_DIR"
git pull

echo "== preflight check =="
bash "$REPO_DIR/scripts/sync_and_check.sh"

echo "== start comfy =="
cd "$COMFY_DIR"
python main.py --listen 0.0.0.0 --port 8188
