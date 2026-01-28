#!/usr/bin/env bash
set -euo pipefail

echo "== video-gen: sync_and_check =="

# ---- paths ----
COMFY_DIR="${COMFY_DIR:-/workspace/ComfyUI}"
REPO_DIR="${REPO_DIR:-/workspace/repos/video-gen}"
ROOT="${ROOT:-/workspace/data}"
MODELS_DIR="${ROOT}/models"
PYTHON="${PYTHON:-python3}"

# ---- 0) basic existence ----
echo "[0] Check ROOT: ${ROOT}"
if [ ! -d "$ROOT" ]; then
  echo "ERROR: ROOT not found at ${ROOT}"
  echo "PVあり: /workspace/data を想定"
  exit 1
fi

echo "[1] Check repo dir: ${REPO_DIR}"
if [ ! -d "$REPO_DIR" ]; then
  echo "ERROR: repo not found at ${REPO_DIR}"
  echo "例: cd /workspace/repos && git clone <repo-url> video-gen"
  exit 1
fi

echo "[2] Check ComfyUI dir: ${COMFY_DIR}"
if [ ! -d "$COMFY_DIR" ]; then
  echo "ERROR: ComfyUI not found at ${COMFY_DIR}"
  echo "例: cd /workspace && git clone https://github.com/comfyanonymous/ComfyUI.git"
  exit 1
fi

# ---- 3) extra_model_paths.yaml ----
echo "[3] Generate extra_model_paths.yaml"
if [ ! -f "$REPO_DIR/scripts/generate_extra_model_paths.sh" ]; then
  echo "ERROR: generate_extra_model_paths.sh not found"
  exit 1
fi
ROOT="$ROOT" COMFY_DIR="$COMFY_DIR" bash "$REPO_DIR/scripts/generate_extra_model_paths.sh"

# ---- 4) required model files (disabled) ----
echo "[4] Skip required model check (disabled)"

# ---- 5) required custom node ----
echo "[5] Check WanVideoWrapper node"
NODE_DIR="${COMFY_DIR}/custom_nodes/ComfyUI-WanVideoWrapper"
if [ ! -d "$NODE_DIR" ]; then
  echo "ERROR: WanVideoWrapper not found: ${NODE_DIR}"
  echo "例: cd ${COMFY_DIR}/custom_nodes && git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git"
  exit 1
fi

echo "[6] OK. Environment looks good."
