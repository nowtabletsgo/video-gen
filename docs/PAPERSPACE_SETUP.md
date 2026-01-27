# Paperspace（Gradient Notebook / Growth）セットアップ手順

本手順は、`video-gen` リポジトリを用いて  
**Wan 2.2 Remix NSFW + SCAIL + Uni3C** の動画生成環境を  
Paperspace Gradient（Notebook / Growth）上で再現するためのものです。

RunPod 手順（`RUNPOD_SETUP.md`）は引き続き参照できますが、**運用の主対象は本ドキュメント**です。

---

## 1. 前提

- Paperspace Gradient Notebook（Growth）
- 公開ポート（`8188`）を使う運用（ComfyUI を外部アクセス可能にする）
- 永続ストレージは `/storage` を利用（モデルは永続化、生成物はR2へ移動）

---

## 2. パスの基本方針（重要）

Paperspace では、次をデフォルトとします（必要なら環境変数で上書き可能）。

- `ROOT=/storage/data`（モデル置き場のルート。`${ROOT}/models/...` に配置）
- `COMFY_DIR=/notebooks/ComfyUI`
- `REPO_DIR=/notebooks/repos/video-gen`

`extra_model_paths.yaml` は `${COMFY_DIR}/extra_model_paths.yaml` に生成します。

---

## 3. ディレクトリ構成（推奨）

```
/notebooks/
  ComfyUI/
  repos/
    video-gen/
/storage/  （永続）
  data/
    models/
    outputs/ （必要なら。生成物は最終的にR2へ）
```

---

## 4. セットアップ手順

### 4.1 ComfyUI の取得

```bash
mkdir -p /notebooks
cd /notebooks
git clone https://github.com/comfyanonymous/ComfyUI.git
```

### 4.2 リポジトリの取得

```bash
mkdir -p /notebooks/repos
cd /notebooks/repos
git clone <repo-url> video-gen
```

### 4.3 モデル配置（永続ストレージ）

`models_manifest.yaml` が唯一の正です。  
`${ROOT}/models` 配下に **manifest と一致するファイルのみ**配置してください。

例（デフォルトROOTの場合）:

```bash
ROOT=/storage/data
mkdir -p "${ROOT}/models"
```

### 4.4 extra_model_paths.yaml の生成

```bash
ROOT=/storage/data \
COMFY_DIR=/notebooks/ComfyUI \
bash /notebooks/repos/video-gen/scripts/generate_extra_model_paths.sh
```

### 4.5 事前チェック

```bash
ROOT=/storage/data \
COMFY_DIR=/notebooks/ComfyUI \
REPO_DIR=/notebooks/repos/video-gen \
bash /notebooks/repos/video-gen/scripts/sync_and_check.sh
```

`sync_and_check.sh` で `ComfyUI-WanVideoWrapper` が無い場合は、案内に従って `custom_nodes` へ追加してください。

### 4.6 ComfyUI 起動（外部アクセス）

```bash
cd /notebooks/ComfyUI
python main.py --listen 0.0.0.0 --port 8188
```

Notebook 側で `8188` を公開できるように設定してください（公開しないとUIにアクセスできません）。

---

## 5. ワンコマンド起動（pull + preflight + start）

```bash
ROOT=/storage/data \
COMFY_DIR=/notebooks/ComfyUI \
REPO_DIR=/notebooks/repos/video-gen \
bash /notebooks/repos/video-gen/scripts/pull_and_start.sh
```

---

## 5.1 /storage に venv を作って “毎回一発起動” する（推奨）

新しいNotebook（新しい環境）になると、PyTorch や ComfyUI 依存が初期化されることがあります。  
その対策として、`/storage`（永続）に venv を作り、以後はその Python で ComfyUI を起動します。

初回のみ（venv作成 + 依存導入）:

```bash
bash /notebooks/repos/video-gen/scripts/paperspace_bootstrap_venv.sh
```

起動（毎回これだけ）:

```bash
bash /notebooks/repos/video-gen/scripts/paperspace_run_comfy_venv.sh
```

---

## 6. 生成物のR2移動（必須）

既存の `RunPod_R2_転送コマンド.txt` の rclone 手順をそのまま流用できます。  
Paperspace の出力先が異なる場合は、ComfyUI の `output/` と `temp/` の実パスに合わせてください。
