#!/usr/bin/env bash
set -euo pipefail

echo "== video-gen: paperspace_bootstrap_venv =="

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
  ROOT="$(detect_path /storage/data /workspace/data || true)"
  ROOT="${ROOT:-/storage/data}"
fi
if [ -z "$COMFY_DIR" ]; then
  COMFY_DIR="$(detect_path /notebooks/ComfyUI /workspace/ComfyUI || true)"
  COMFY_DIR="${COMFY_DIR:-/notebooks/ComfyUI}"
fi
if [ -z "$REPO_DIR" ]; then
  REPO_DIR="$(detect_path /notebooks/repos/video-gen /workspace/repos/video-gen || true)"
  REPO_DIR="${REPO_DIR:-/notebooks/repos/video-gen}"
fi

SYS_PY="${SYS_PY:-}"
if [ -z "$SYS_PY" ]; then
  if command -v python3 >/dev/null 2>&1; then
    SYS_PY="python3"
  elif command -v python >/dev/null 2>&1; then
    SYS_PY="python"
  else
    echo "ERROR: python not found"
    exit 1
  fi
fi

VENV_DIR="${VENV_DIR:-}"
if [ -z "$VENV_DIR" ]; then
  if [ -d /storage ]; then
    VENV_DIR="/storage/venv-comfyui"
  else
    VENV_DIR="${ROOT}/venv-comfyui"
  fi
fi

TORCH_INDEX_URL="${TORCH_INDEX_URL:-https://download.pytorch.org/whl/cu121}"
TORCH_VERSION="${TORCH_VERSION:-2.4.1+cu121}"
TORCHVISION_VERSION="${TORCHVISION_VERSION:-0.19.1+cu121}"
TORCHAUDIO_VERSION="${TORCHAUDIO_VERSION:-2.4.1+cu121}"

echo "[0] Paths"
echo "  ROOT     = ${ROOT}"
echo "  COMFY_DIR= ${COMFY_DIR}"
echo "  REPO_DIR = ${REPO_DIR}"
echo "  VENV_DIR = ${VENV_DIR}"
echo "  SYS_PY   = ${SYS_PY}"

if [ ! -d "$COMFY_DIR" ]; then
  echo "ERROR: COMFY_DIR not found: ${COMFY_DIR}"
  exit 1
fi
if [ ! -d "$REPO_DIR" ]; then
  echo "ERROR: REPO_DIR not found: ${REPO_DIR}"
  exit 1
fi

echo "[1] Create venv (if missing)"
if [ ! -x "${VENV_DIR}/bin/python" ]; then
  "$SYS_PY" -m venv "$VENV_DIR"
fi

PY="${VENV_DIR}/bin/python"
PIP="${VENV_DIR}/bin/pip"

echo "[2] Ensure pip"
"$PY" -m ensurepip --upgrade >/dev/null 2>&1 || true
"$PY" -m pip install -U pip

echo "[3] Install/upgrade PyTorch (cu121) in venv"
"$PIP" install \
  --index-url "$TORCH_INDEX_URL" \
  --extra-index-url https://pypi.org/simple \
  "torch==${TORCH_VERSION}" \
  "torchvision==${TORCHVISION_VERSION}" \
  "torchaudio==${TORCHAUDIO_VERSION}"

echo "[3.1] Fix CUDA wheel lib compatibility (nvJitLink/cusparse)"
# Some notebook images ship /usr/local/cuda libs that conflict with pip CUDA wheels.
# Pinning these and preferring their /nvidia/*/lib paths avoids runtime symbol errors.
"$PIP" install --force-reinstall \
  "nvidia-nvjitlink-cu12==12.1.105" \
  "nvidia-cusparse-cu12==12.1.0.106"

echo "[4] Install ComfyUI requirements in venv"
"$PIP" install -r "${COMFY_DIR}/requirements.txt"

echo "[5] Install custom_nodes requirements (if present)"
if [ -d "${COMFY_DIR}/custom_nodes" ]; then
  while IFS= read -r req; do
    "$PIP" install -r "$req"
  done < <(find "${COMFY_DIR}/custom_nodes" -maxdepth 3 -type f -name requirements.txt -print 2>/dev/null || true)
fi

echo "[6] Done."
echo "Next: bash ${REPO_DIR}/scripts/paperspace_run_comfy_venv.sh"
