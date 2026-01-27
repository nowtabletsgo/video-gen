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
if [ -z "$ROOT" ]; then
  ROOT="$(detect_path /storage/data /workspace/data || true)"
  ROOT="${ROOT:-/workspace/data}"
fi
if [ -z "$COMFY_DIR" ]; then
  COMFY_DIR="$(detect_path /notebooks/ComfyUI /workspace/ComfyUI || true)"
  COMFY_DIR="${COMFY_DIR:-/workspace/ComfyUI}"
fi
OUT="${EXTRA_MODEL_PATHS:-${COMFY_DIR}/extra_model_paths.yaml}"
MODELS_DIR="${ROOT}/models"

cat > "$OUT" <<EOF
video-gen:
  base_path: ${MODELS_DIR}
  checkpoints:
    - diffusion_models
    - diffusion_models/sfw
    - diffusion_models/nsfw
  diffusion_models:
    - diffusion_models
    - diffusion_models/sfw
    - diffusion_models/nsfw
  text_encoders:
    - text_encoders
    - text_encoders/sfw
    - text_encoders/nsfw
  scail: scail
  controlnet: controlnet
  onnx: onnx
  clip_vision: clip_vision
  loras:
    - lora/sfw
    - lora/nsfw
  vae:
    - wanvideo
    - vae
    - vae/sfw
    - vae/nsfw
  wanvideo: wanvideo
EOF

echo "Wrote ${OUT}"
