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
- PVは最小化し、モデル本体は外部ストレージから同期

---

## 2. ROOT の定義（必須）

ROOT は **models の1個上** に固定します。

- PVあり: `ROOT=/workspace/data`
- PVなし: `ROOT=/workspace`

モデル配置先は常に `${ROOT}/models/...` です。

---

## 3. ディレクトリ構成

/workspace/
├ ComfyUI/
├ repos/
│ └ video-gen/
└ data/ （PVあり時のみ）

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

PVなしの場合は `ROOT=/workspace` に置き換えます。

### 4.4 モデル同期（外部ストレージ）

`models_manifest.yaml` が唯一の正です。  
外部ストレージから **manifest と一致するファイルのみ** 同期してください。

例（方針のみ）:

- rclone sync
- aws s3 sync
- huggingface-cli download

同期先は必ず `${ROOT}/models` 配下にしてください。

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
- フレーム: 24
- Steps: 16
- 参照動画: 3〜5秒

目的は **赤ノードや不足モデルの検出** のみです。
