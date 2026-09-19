#!/bin/bash
# =====================================================================
# 本地 AI 服务管理脚本 (oMLX 多模型服务 · 交互面板)
#
# 两种用法:
#   ./start_agent.sh                   → 交互面板
#   ./start_agent.sh start [模型]      → 一键启动（默认 oq4e）
#   ./start_agent.sh stop|restart|status|log|model <别名>
#
# 模型切换逻辑全部委托给 ./switch-model.sh
# 客户端直接 omlx launch claude|codex|hermes 接入，无需 CCR 中转
# =====================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh"

# 模型别名与展示名
MODEL_ALIASES=(oq4e 8bit)
MODEL_LABELS=(
  "oq4e — Qwen3.8-27B-oQ4e-mtp（OptiQ 4bit + MTP，日常编码主力）"
  "8bit — Qwen3.8-27B-8bit（8bit 高精度 / 多模态）"
)

pick_model() {
  echo "" >&2
  echo "--- 可选模型 ---" >&2
  local i
  for i in "${!MODEL_ALIASES[@]}"; do
    echo "  $((i+1))) ${MODEL_LABELS[$i]}" >&2
  done
  echo "----------------" >&2
  read -rp "请输入模型编号: " idx
  case "$idx" in
    ''|*[!0-9]*) echo "❌ 输入无效" >&2; return 1 ;;
  esac
  if [ "$idx" -ge 1 ] && [ "$idx" -le "${#MODEL_ALIASES[@]}" ]; then
    echo "${MODEL_ALIASES[$((idx-1))]}"
  else
    echo "❌ 编号超出范围" >&2; return 1
  fi
}

start_server() {
  if omlx_up; then
    echo "⚠️  oMLX 服务已在运行。换模型请用「切换模型」（无需重启服务）。"
    return 1
  fi
  echo "🧠 启动 oMLX ..."
  omlx start
  echo "✅ 服务已启动，端口: $OMLX_PORT   日志: $OMLX_LOG"
  echo "ℹ️  模型在第一次请求时才加载，首轮等待属正常"
}

switch_server() {
  local alias
  alias=$(pick_model) || return 1
  "$SCRIPT_DIR/switch-model.sh" "$alias"
}

stop_server() {
  if omlx_up; then
    omlx stop
    echo "🛑 oMLX 服务已停止"
  else
    echo "ℹ️  oMLX 服务本就没在运行"
  fi
}

run_claude_code() {
  omlx launch claude   # oMLX 原生接入，自动配好 base_url / 三层模型映射
}

run_hermes_agent() {
  omlx launch hermes
}

cmd_status() {
  "$SCRIPT_DIR/switch-model.sh" status
}

# ===================== 非交互快捷命令 =====================
if [ $# -gt 0 ]; then
  case "$1" in
    start)
      alias="${2:-oq4e}"
      valid=0
      for m in "${MODEL_ALIASES[@]}"; do [ "$alias" = "$m" ] && valid=1; done
      if [ "$valid" != 1 ]; then
        echo "❌ 未知模型: $alias（可选: ${MODEL_ALIASES[*]}）"; exit 1
      fi
      if omlx_up; then
        echo "ℹ️  oMLX 服务已在跑（多模型服务，无需重启）"
      else
        start_server
      fi
      "$SCRIPT_DIR/switch-model.sh" "$alias"
      echo ""
      echo "🎉 就绪。客户端: omlx launch claude / codex / hermes"
      cmd_status
      ;;
    stop)
      stop_server
      ;;
    restart)
      omlx restart
      ;;
    status)
      cmd_status
      ;;
    log)
      tail -f "$OMLX_LOG"
      ;;
    model)
      [ $# -ge 2 ] || { echo "用法: $0 model <oq4e|8bit>"; exit 1; }
      "$SCRIPT_DIR/switch-model.sh" "$2"
      ;;
    *)
      echo "用法: $0 [start [oq4e|8bit] | stop | restart | status | log | model <别名>]"
      exit 1
      ;;
  esac
  exit 0
fi

# ===================== 交互面板 =====================
while true; do
  echo ""
  echo "================ 本地 AI 服务面板 (oMLX) ================"
  if omlx_up; then
    echo " oMLX 服务: 🟢 端口 $OMLX_PORT   已加载: $(omlx_model_ids | tr '\n' ' ')"
  else
    echo " oMLX 服务: ⚪ 未运行"
  fi
  echo "------------------------------------------------"
  echo " 1) 启动服务               5) 进入 Claude Code (omlx launch)"
  echo " 2) 切换模型（改 Codex 默认） 6) 进入 Hermes agent"
  echo " 3) 停止服务               7) 查看实时日志"
  echo " 4) 查看状态               0) 退出（服务保持后台）"
  echo "================================================"
  read -rp "选择: " choice

  case $choice in
    1) start_server ;;
    2) switch_server ;;
    3) stop_server ;;
    4) cmd_status ;;
    5)
      if omlx_up; then run_claude_code
      else echo "❌ 服务未启动，请先选 1"; fi
      ;;
    6)
      if omlx_up; then run_hermes_agent
      else echo "❌ 服务未启动，请先选 1"; fi
      ;;
    7)
      echo "（Ctrl+C 退出查看，不影响服务）"; sleep 1
      tail -f "$OMLX_LOG"
      ;;
    0)
      echo "👋 面板退出，后台服务保持运行"; exit 0
      ;;
    *)
      echo "❌ 无效输入"
      ;;
  esac
done
