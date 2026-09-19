#!/bin/bash
# switch-model.sh — 本地 oMLX 模型服务管理
#
# 用法:
#   ./switch-model.sh oq4e     # Qwen3.8-27B-oQ4e-mtp (OptiQ 4bit + MTP，快)
#   ./switch-model.sh 8bit     # Qwen3.8-27B-8bit (8bit 高精度)
#   ./switch-model.sh status   # 查看当前运行状态
#   ./switch-model.sh list     # 列出服务已加载的模型
#   ./switch-model.sh start|stop|restart
#
# 说明: oMLX 是多模型服务 —— 一个后台服务托管 MODELS_DIR 下全部模型
# (LRU 内存管理)，切换模型不需要重启服务，只需更新客户端使用的 model。
#
# 配置写在 ./config.sh 里，也可通过环境变量覆盖。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh"

log() { echo "[$(date '+%H:%M:%S')] $*"; }
die() { log "错误: $*"; exit 1; }
usage() { echo "用法: $0 {oq4e|8bit|status|list|start|stop|restart}"; exit 1; }

# 别名 → model_id
alias_to_model() {
  case "$1" in
    oq4e) echo "$MODEL_OQ4E" ;;
    8bit) echo "$MODEL_8BIT" ;;
    *) return 1 ;;
  esac
}

codex_current_model() {
  [ -f "$CODEX_CONFIG" ] || return 0
  sed -n 's/^model = "\(.*\)"/\1/p' "$CODEX_CONFIG" | head -1
}

show_status() {
  echo "───────────────"
  if omlx_up; then
    echo " oMLX 服务: 🟢 http://${OMLX_HOST}:${OMLX_PORT}（多模型 LRU）"
    echo " 已加载模型:"
    omlx_model_ids | sed 's/^/   - /' || echo "   (获取失败)"
  else
    echo " oMLX 服务: ⚪ 未运行"
  fi
  local m; m=$(codex_current_model)
  echo " Codex CLI:  model = ${m:-<未配置>}  ($CODEX_CONFIG)"
  echo "───────────────"
  exit 0
}

ensure_server() {
  if omlx_up; then return 0; fi
  log "oMLX 服务未运行，正在启动..."
  omlx start || die "omlx start 失败，检查 oMLX app 或日志: $OMLX_LOG"
  local waited=0
  while ! omlx_up; do
    sleep 1; ((++waited))
    if ((waited >= STOP_TIMEOUT)); then
      die "服务 ${STOP_TIMEOUT}s 内未就绪，查看 $OMLX_LOG"
    fi
  done
  log "oMLX 服务就绪 (端口 $OMLX_PORT)"
}

switch_model() {
  local alias="$1" model_id
  model_id=$(alias_to_model "$alias") || die "未知模型: $alias（可选: oq4e 8bit）"
  ensure_server

  if ! omlx_model_ids | grep -qx "$model_id"; then
    die "服务里没有模型 $model_id，确认 $MODELS_DIR/$model_id 目录存在且完整"
  fi

  if [ -f "$CODEX_CONFIG" ]; then
    local current; current=$(codex_current_model)
    if [ "$current" = "$model_id" ]; then
      log "Codex 已在使用 $model_id，无需修改"
    else
      sed -i '' "s|^model = .*|model = \"$model_id\"|" "$CODEX_CONFIG"
      log "Codex 默认模型: ${current:-<无>} → $model_id"
    fi
  else
    log "未找到 $CODEX_CONFIG，跳过 Codex 更新"
  fi

  echo ""
  echo "🎉 就绪。新开会话的 codex 即生效；其他客户端:"
  echo "   omlx launch claude --model $model_id   # Claude Code（无需 CCR）"
  echo "   omlx launch hermes --model $model_id   # Hermes agent"
  exit 0
}

case "${1:-}" in
  oq4e|8bit) switch_model "$1" ;;
  status)    show_status ;;
  list)
    if omlx_up; then omlx_model_ids; else echo "oMLX 服务未运行"; fi
    exit 0 ;;
  start)     omlx start; exit 0 ;;
  stop)      omlx stop; exit 0 ;;
  restart)   omlx restart; exit 0 ;;
  *)         usage ;;
esac
