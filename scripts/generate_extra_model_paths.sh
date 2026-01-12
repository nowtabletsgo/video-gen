#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-/workspace/data}"
COMFY_DIR="${COMFY_DIR:-/workspace/ComfyUI}"
OUT="${EXTRA_MODEL_PATHS:-${COMFY_DIR}/extra_model_paths.yaml}"
MODELS_DIR="${ROOT}/models"

cat > "$OUT" <<EOF
- base_path: ${MODELS_DIR}
  checkpoints: diffusion_models
  diffusion_models: diffusion_models
  text_encoders: text_encoders
  scail: scail
  controlnet: controlnet
  onnx: onnx
  clip_vision: clip_vision
  loras: lora
  vae: wanvideo
  wanvideo: wanvideo
EOF

echo "Wrote ${OUT}"
