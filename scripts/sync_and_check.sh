#!/usr/bin/env bash
set -euo pipefail

echo "== video-gen: sync_and_check =="

# ---- paths (cloud fixed) ----
COMFY_DIR="/workspace/ComfyUI"
REPO_DIR="/workspace/repos/video-gen"
PV_DIR="/workspace/data"

# ---- 0) basic existence ----
echo "[0] Check PV mount: ${PV_DIR}"
if [ ! -d "$PV_DIR" ]; then
  echo "ERROR: PV not mounted at ${PV_DIR}"
  echo "RunPodで Persistent Volume の Mount Path を /workspace/data に設定してください。"
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

# ---- 3) required model files ----
echo "[3] Check required models under ${PV_DIR}/models"

need_files=(
  "${PV_DIR}/models/wan2.2/Wan2.2_Remix_NSFW_i2v_14b_high_lighting_v2.1.safetensors"
  "${PV_DIR}/models/wan2.2/Wan2.2_Remix_NSFW_i2v_14b_low_lighting_v2.1.safetensors"
  "${PV_DIR}/models/text_encoders/nsfw_wan_umt5-xxl.safetensors"
  "${PV_DIR}/models/scail/Wan21-14B-SCAIL-preview_bf16.safetensors"
  "${PV_DIR}/models/uni3c/Wan21_Uni3C_controlnet_fp16.safetensors"
)

missing=0
for f in "${need_files[@]}"; do
  if [ ! -f "$f" ]; then
    echo "MISSING: $f"
    missing=1
  else
    echo "OK:      $f"
  fi
done

if [ "$missing" -ne 0 ]; then
  echo "ERROR: required model files are missing."
  echo "models_manifest.yaml を見て /workspace/data/models に配置してください。"
  exit 1
fi

# ---- 4) required custom node ----
echo "[4] Check WanVideoWrapper node"
NODE_DIR="${COMFY_DIR}/custom_nodes/ComfyUI-WanVideoWrapper"
if [ ! -d "$NODE_DIR" ]; then
  echo "ERROR: WanVideoWrapper not found: ${NODE_DIR}"
  echo "例: cd ${COMFY_DIR}/custom_nodes && git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git"
  exit 1
fi

echo "[5] OK. Environment looks good."
