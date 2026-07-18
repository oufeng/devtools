#!/bin/bash
# switch-model.sh — 一键切换本地 optiq 模型服务
#
# 用法:
#   ./switch-model.sh 27b     # Qwen3.6-27B
#   ./switch-model.sh 35b     # Qwen3.6-35B-A3B (MoE)
#   ./switch-model.sh gemma   # Gemma 4 31B (QAT)
#
# 首次使用前，先为两个 Qwen 模型生成 KV cache 配置（各跑一次即可）:
#   optiq kv-cache ~/Developer/models/Qwen3.6-27B-OptiQ-4bit \
#       --target-bits 5.0 --candidate-bits 4,8 -o ~/Developer/models/kv/qwen36_27b
#   optiq kv-cache ~/Developer/models/Qwen3.6-35B-A3B-OptiQ-4bit \
#       --target-bits 5.0 --candidate-bits 4,8 -o ~/Developer/models/kv/qwen36_35b

set -euo pipefail

# ================= 配置区 =================
MODELS=~/Developer/models
KV_DIR="$MODELS/kv"

PORT=8080
STOP_TIMEOUT=30   # 等旧服务释放端口的最长秒数

# ================= 工具函数 =================
log() { echo "[$(date '+%H:%M:%S')] $*"; }
die() { log "错误: $*"; exit 1; }
usage() { echo "用法: $0 {27b|35b|gemma}"; exit 1; }

# 停掉旧服务，并等端口真正释放
stop_server() {
  log "停止旧服务..."
  pkill -f "optiq serve" 2>/dev/null || true

  local waited=0
  while lsof -nP -iTCP:$PORT -sTCP:LISTEN >/dev/null 2>&1; do
    sleep 1; ((++waited))
    if ((waited >= STOP_TIMEOUT)); then
      lsof -nP -iTCP:$PORT -sTCP:LISTEN
      die "端口 $PORT 等了 ${STOP_TIMEOUT}s 仍被占用（占用进程见上方）"
    fi
  done
  log "端口 $PORT 已释放"
}

# ================= 模型定义 =================
# 每个配置函数负责设置两个全局变量：
#   MODEL_PATH — 模型目录
#   MODEL_ARGS — 传给 optiq serve 的额外参数（数组）

# 两个 Qwen 模型逻辑相同，共用一个函数
config_qwen() {  # $1=模型目录名  $2=kv 配置目录名
  MODEL_PATH="$MODELS/$1"
  local kv="$KV_DIR/$2/kv_config.json"
  [ -f "$kv" ] || die "缺少 $kv，先运行脚本头部的 optiq kv-cache 命令"
  MODEL_ARGS=(--mtp --kv-config "$kv")
}

config_gemma() {
  MODEL_PATH="$MODELS/gemma-4-31B-it-qat-OptiQ-4bit"
  MODEL_ARGS=(--drafter google/gemma-4-31B-it-qat-q4_0-unquantized-assistant)

  local kv="$KV_DIR/gemma4_31b_qat/kv_config.json"
  if [ -f "$kv" ]; then
    MODEL_ARGS+=(--kv-config "$kv")
  else
    log "提示: 未找到 kv_config，Gemma 将使用 fp16 KV"
  fi
}

# ================= 主流程 =================
case "${1:-}" in
  27b)   config_qwen Qwen3.6-27B-OptiQ-4bit     qwen36_27b ;;
  35b)   config_qwen Qwen3.6-35B-A3B-OptiQ-4bit qwen36_35b ;;
  gemma) config_gemma ;;
  *)     usage ;;
esac

stop_server

log "启动: $MODEL_PATH"
log "加载中（约 30-60 秒无输出属正常）..."
exec optiq serve --model "$MODEL_PATH" "${MODEL_ARGS[@]}" \
  --max-context auto --max-concurrent 8 --port $PORT