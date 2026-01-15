# RunPod セットアップ手順（Wan 2.2 + SCAIL + Uni3C 専用）

本手順は、`video-gen` リポジトリを用いて  
**Wan 2.2 Remix NSFW + SCAIL + Uni3C** の動画生成環境を  
RunPod 上で再現するためのものです。

本環境は **動画生成専用** とし、画像生成用 ComfyUI とは分離します。

---

## 1. 前提

- RunPod アカウント
- GPU: RTX 4090 / A100 / H100 クラス推奨
- 本リポジトリ：`video-gen`
- PVにモデル本体を常設（決定モデルのみ）
- 生成物は必ずR2へ移動

---

## 2. ROOT の定義（必須）

ROOT は **models の1個上** に固定します。

`ROOT=/workspace/data`

モデル配置先は常に `${ROOT}/models/...` です。

---

## 3. ディレクトリ構成

/workspace/
├ ComfyUI/
├ repos/
│ └ video-gen/
└ data/ （PV）

モデル配置先（両モード共通）:

${ROOT}/models/
├ diffusion_models/
├ text_encoders/
├ scail/
├ controlnet/
├ onnx/
├ clip_vision/
└ wanvideo/

---

## 4. セットアップ手順

### 4.1 ComfyUI 本体の取得

```bash
cd /workspace
git clone https://github.com/comfyanonymous/ComfyUI.git
```

### 4.2 リポジトリの取得

```bash
mkdir -p /workspace/repos
cd /workspace/repos
git clone <repo-url> video-gen
```

### 4.3 extra_model_paths.yaml の生成（方式A）

```bash
ROOT=/workspace/data \
COMFY_DIR=/workspace/ComfyUI \
bash /workspace/repos/video-gen/scripts/generate_extra_model_paths.sh
```

PVなしは使用しません（モデルはPV常設）。

### 4.4 モデル配置（PV常設）

`models_manifest.yaml` が唯一の正です。  
`${ROOT}/models` 配下に **manifest と一致するファイルのみ** 配置してください。

初回のみ HF からダウンロードしてPVに固定配置します。

### 4.5 事前チェック

```bash
ROOT=/workspace/data \
bash /workspace/repos/video-gen/scripts/sync_and_check.sh
```

### 4.6 ComfyUI 起動

```bash
cd /workspace/ComfyUI
python main.py --listen 0.0.0.0 --port 8188
```

---

## 5. 最小テスト条件（品質不問）

- 解像度: 512x768
- FPS: 24
- フレーム: 48（目安）
- Steps: 10〜16（検証で決定）
- 参照動画: 3〜5秒

目的は **赤ノードや不足モデルの検出** のみです。

---

## 6. 生成物のR2移動（必須）

生成後、以下を実行してR2へ移動します（PVに残さない）。

```bash
rclone sync /workspace/ComfyUI/output r2:wan01/runpod/output --progress
rclone sync /workspace/ComfyUI/temp   r2:wan01/runpod/temp --progress
```
