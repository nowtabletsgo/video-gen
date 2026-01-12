# RunPod セットアップ手順（ComfyUI / SCAIL + Uni3C + Wan）

この手順は「起動→生成→停止」を前提に、GPU課金時間を最小化するためのもの。

## 0. 前提
- GPU: A100 80GB（推奨）
- Pod Template: RunPod PyTorch（汎用）
- Pricing: On-Demand（最初はSpot非推奨）
- Persistent Volume (PV): ON
  - Mount Path: /workspace/data

## 1. Pod作成（RunPod UI）
1) GPU選択: A100 80GB（SXM/PCIeどちらでも可）
2) GPU count: 1
3) Pricing: On-Demand
4) Template: RunPod PyTorch
5) Storage:
   - Persistent Volume: ON
   - Mount Path: /workspace/data
6) Deploy → 起動

## 2. SSHで接続（起動後）
RunPodの Connect から SSH で接続。

まずPVが見えることを確認:
```bash
ls -la /workspace
ls -la /workspace/data
