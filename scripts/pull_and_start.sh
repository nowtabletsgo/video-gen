#!/usr/bin/env bash
set -euo pipefail

detect_path() {
  local candidate
  for candidate in "$@"; do
    if [ -n "$candidate" ] && [ -d "$candidate" ]; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

ROOT="${ROOT:-}"
COMFY_DIR="${COMFY_DIR:-}"
REPO_DIR="${REPO_DIR:-}"

if [ -z "$ROOT" ]; then
  ROOT="$(detect_path /workspace/data /storage/data || true)"
  ROOT="${ROOT:-/workspace/data}"
fi
if [ -z "$COMFY_DIR" ]; then
  COMFY_DIR="$(detect_path /workspace/ComfyUI /notebooks/ComfyUI || true)"
  COMFY_DIR="${COMFY_DIR:-/workspace/ComfyUI}"
fi
if [ -z "$REPO_DIR" ]; then
  REPO_DIR="$(detect_path /workspace/repos/video-gen /notebooks/repos/video-gen || true)"
  REPO_DIR="${REPO_DIR:-/workspace/repos/video-gen}"
fi

echo "== pull repo =="
cd "$REPO_DIR"
git pull

echo "== preflight check =="
ROOT="$ROOT" COMFY_DIR="$COMFY_DIR" REPO_DIR="$REPO_DIR" bash "$REPO_DIR/scripts/sync_and_check.sh"

echo "== start comfy =="
cd "$COMFY_DIR"
python main.py --listen 0.0.0.0 --port 8188
