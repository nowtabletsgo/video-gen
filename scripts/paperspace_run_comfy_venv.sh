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
NVJ="$("$PY" - <<'PY'
try:
  import nvidia.nvjitlink, pathlib
  print((pathlib.Path(nvidia.nvjitlink.__file__).resolve().parent / "lib").as_posix())
except Exception:
  print("")
PY
)"
CUS="$("$PY" - <<'PY'
try:
  import nvidia.cusparse, pathlib
  print((pathlib.Path(nvidia.cusparse.__file__).resolve().parent / "lib").as_posix())
except Exception:
  print("")
PY
)"
if [ -n "$NVJ" ] && [ -n "$CUS" ]; then
  export LD_LIBRARY_PATH="${NVJ}:${CUS}:${LD_LIBRARY_PATH:-}"
fi

echo "[1] Preflight (extra_model_paths + manifest check)"
chmod +x "$REPO_DIR/scripts/"*.sh 2>/dev/null || true
ROOT="$ROOT" COMFY_DIR="$COMFY_DIR" REPO_DIR="$REPO_DIR" PYTHON="$PY" bash "$REPO_DIR/scripts/sync_and_check.sh"

echo "[2] Start ComfyUI (port ${COMFY_PORT})"
cd "$COMFY_DIR"
exec "$PY" main.py --listen 0.0.0.0 --port "$COMFY_PORT"

