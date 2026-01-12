# RunPod セットアップ手順（Wan 2.2 + SCAIL + Uni3C 専用）

本手順は、`video-gen` GitHub リポジトリを用いて  
**Wan 2.2 Remix NSFW + SCAIL + Uni3C** による動画生成環境を  
RunPod 上で再現するためのものです。

本環境は **動画生成専用** とし、画像生成用 ComfyUI とは分離します。

---

## 1. 前提

- RunPod アカウント
- GPU: RTX 4090 / A100 / H100 クラス推奨
- Persistent Volume（以下 PV）を使用
- 本リポジトリ：`video-gen`

---

## 2. RunPod Pod 作成

1. RunPod で新規 Pod 作成
2. テンプレート：Ubuntu / CUDA 対応
3. **Persistent Volume を有効化**
   - Mount Path: `/workspace/data`

---

## 3. ディレクトリ構成（確定）

### 3.1 全体構造
/workspace/
├ ComfyUI/ ← ComfyUI 本体（git clone）
├ repos/
│ └ video-gen/ ← この GitHub リポジトリ
└ data/ ← Persistent Volume
├ models/
├ inputs/
├ outputs/
└ cache/


---

## 4. セットアップ手順

### 4.1 ComfyUI 本体の取得

```bash
cd /workspace
git clone https://github.com/comfyanonymous/ComfyUI.git
