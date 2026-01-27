#!/usr/bin/env bash
set -euo pipefail

echo "== video-gen: paperspace_run_comfy_venv =="

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
COMFY_PORT="${COMFY_PORT:-6006}"

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

VENV_DIR="${VENV_DIR:-}"
if [ -z "$VENV_DIR" ]; then
  if [ -d /storage ]; then
    VENV_DIR="/storage/venv-comfyui"
  else
    VENV_DIR="${ROOT}/venv-comfyui"
  fi
fi

PY="${VENV_DIR}/bin/python"
if [ ! -x "$PY" ]; then
  echo "ERROR: venv python not found: ${PY}"
  echo "Run: bash ${REPO_DIR}/scripts/paperspace_bootstrap_venv.sh"
  exit 1
fi

echo "[0] Resolve CUDA lib paths (prefer venv site-packages)"
# Ensure tools invoked by custom nodes (e.g. ComfyUI-Manager) resolve to the venv first.
export PATH="${VENV_DIR}/bin:${PATH}"

# Avoid Python import-based discovery because some environments treat `nvidia.*` as namespace packages
# (e.g. __file__ can be None). Instead, locate the shared libraries directly inside the venv.
NVJ_LIB12="$(find "$VENV_DIR" -type f -path "*/nvidia/nvjitlink/lib/libnvJitLink.so.12" -print -quit 2>/dev/null || true)"
if [ -z "$NVJ_LIB12" ]; then
  NVJ_LIB12="$(find "$VENV_DIR" -type f -name "libnvJitLink.so.12" -print -quit 2>/dev/null || true)"
fi
CUS_LIB12="$(find "$VENV_DIR" -type f -path "*/nvidia/cusparse/lib/libcusparse.so.12" -print -quit 2>/dev/null || true)"
if [ -z "$CUS_LIB12" ]; then
  CUS_LIB12="$(find "$VENV_DIR" -type f -name "libcusparse.so.12" -print -quit 2>/dev/null || true)"
fi

if [ -z "$NVJ_LIB12" ] || [ -z "$CUS_LIB12" ]; then
  echo "ERROR: Could not find CUDA wheel libs inside venv."
  echo "  nvjitlink: ${NVJ_LIB12:-<missing>}"
  echo "  cusparse : ${CUS_LIB12:-<missing>}"
  echo "Run bootstrap again:"
  echo "  bash ${REPO_DIR}/scripts/paperspace_bootstrap_venv.sh"
  exit 1
fi

NVJ_DIR="$(dirname "$NVJ_LIB12")"
CUS_DIR="$(dirname "$CUS_LIB12")"
echo "  NVJITLINK_LIB=${NVJ_LIB12}"
echo "  CUSPARSE_LIB=${CUS_LIB12}"

# Ensure these take precedence over system CUDA libs.
TORCH_LIB_DIR="$(find "$VENV_DIR" -type d -path "*/site-packages/torch/lib" -print -quit 2>/dev/null || true)"
if [ -n "$TORCH_LIB_DIR" ]; then
  export LD_LIBRARY_PATH="${TORCH_LIB_DIR}:${NVJ_DIR}:${CUS_DIR}:${LD_LIBRARY_PATH:-}"
else
  export LD_LIBRARY_PATH="${NVJ_DIR}:${CUS_DIR}:${LD_LIBRARY_PATH:-}"
fi
export LD_PRELOAD="${NVJ_LIB12}${LD_PRELOAD:+:${LD_PRELOAD}}"

echo "[1] Preflight (extra_model_paths + manifest check)"
chmod +x "$REPO_DIR/scripts/"*.sh 2>/dev/null || true
ROOT="$ROOT" COMFY_DIR="$COMFY_DIR" REPO_DIR="$REPO_DIR" PYTHON="$PY" bash "$REPO_DIR/scripts/sync_and_check.sh"

echo "[2] Torch import sanity check"
if ! "$PY" - <<PY >/dev/null 2>&1
import torch  # noqa: F401
PY
then
  echo "ERROR: torch failed to import (likely CUDA lib mismatch)."
  echo "Try re-running bootstrap to repin CUDA wheels:"
  echo "  bash ${REPO_DIR}/scripts/paperspace_bootstrap_venv.sh"
  echo
  echo "Debug (run these and paste output):"
  echo "  ${PY} -c \"import torch; print(torch.__version__)\""
  echo "  find ${VENV_DIR} -name 'libnvJitLink.so.12' -o -name 'libcusparse.so.12' | head"
  exit 1
fi

echo "[3] Start ComfyUI (port ${COMFY_PORT})"
cd "$COMFY_DIR"
exec "$PY" main.py --listen 0.0.0.0 --port "$COMFY_PORT"
