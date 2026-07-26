#!/bin/bash
# =====================================================================
# 本地 AI 服务管理脚本 (48GB Mac · optiq · MLX · CCR 桥接)
#
# 两种用法:
#   ./start_agent.sh                → 交互面板
#   ./start_agent.sh start [模型]   → 一键启动（默认 27b）
#   ./start_agent.sh stop|restart|status|log
#
# 模型切换逻辑全部委托给 ./switch-model.sh
# 一次性前置: CCR 应用里配好供应商(optiq)/路由/档案(名为 code)，端口 3456
# =====================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh"

mkdir -p "$LOG_DIR"

# 模型别名与展示名
MODEL_ALIASES=(27b 35b gemma)
MODEL_LABELS=(
  "27b  — Qwen3.6-27B（深度推理 / agent 攻坚）"
  "35b  — Qwen3.6-35B-A3B（编码主力 / MoE）"
  "gemma — Gemma 4 31B（通用日常 / 多模态）"
)

server_running() { lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; }
ccr_running()    { lsof -nP -iTCP:"$CCR_PORT" -sTCP:LISTEN >/dev/null 2>&1; }

current_model() {
  local cmdline
  cmdline=$(pgrep -af "optiq serve" 2>/dev/null | head -1 | cut -d' ' -f2- || true)
  echo "$cmdline" | sed -n 's/.*--model \([^ ]*\).*/\1/p' | head -n1
}

pick_model() {
  echo "" >&2
  echo "--- 可选模型 ---" >&2
  local i
  for i in "${!MODEL_ALIASES[@]}"; do
    echo "  $((i+1))) ${MODEL_LABELS[$i]}" >&2
  done
  echo "----------------" >&2
  read -rp "请输入模型编号 (1=27b, 2=35b, 3=gemma): " idx
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
  local alias="$1"
  if server_running; then
    echo "⚠️  服务已在运行（$(basename "$(current_model)")）。换模型请用「切换模型」。"
    return 1
  fi
  echo "🧠 启动 $alias ..."
  nohup "$SCRIPT_DIR/switch-model.sh" "$alias" > "$LOG_DIR/optiq.log" 2>&1 &
  disown
  sleep 2
  if server_running; then
    echo "✅ 服务已启动，端口: $PORT   日志: $LOG_DIR/optiq.log"
    echo "ℹ️  模型在第一次请求时才加载，首轮等待约 1 分钟属正常"
  else
    echo "❌ 启动失败，最近日志:"; tail -n 20 "$LOG_DIR/optiq.log"; return 1
  fi
}

switch_server() {
  local alias
  alias=$(pick_model) || return 1
  echo "🔄 切换到 $alias ..."
  nohup "$SCRIPT_DIR/switch-model.sh" "$alias" > "$LOG_DIR/optiq.log" 2>&1 &
  disown
  sleep 2
  if server_running; then
    echo "✅ 已切换，端口: $PORT   日志: $LOG_DIR/optiq.log"
  else
    echo "❌ 切换失败，最近日志:"; tail -n 20 "$LOG_DIR/optiq.log"; return 1
  fi
}

stop_server() {
  if server_running; then
    pkill -f "optiq serve" 2>/dev/null || true
    local waited=0
    while server_running; do
      sleep 1; ((++waited))
      if ((waited >= STOP_TIMEOUT)); then
        echo "⚠️  等了 ${STOP_TIMEOUT}s 服务仍未停止"; return 1
      fi
    done
    echo "🛑 模型服务已停止"
  else
    echo "ℹ️  模型服务本就没在运行"
  fi
}

ensure_ccr() {
  if ccr_running; then return 0; fi
  if ! command -v ccr >/dev/null 2>&1; then
    echo "❌ 未找到 ccr 命令（npm install -g @musistudio/claude-code-router）"
    return 1
  fi
  echo "🌉 启动 CCR 服务+网关 ..."
  ccr start --no-open >/dev/null 2>&1 || true   # 输出含管理令牌，不回显更安全
  sleep 3
  if ccr_running; then
    echo "✅ CCR 网关就绪"
  else
    echo "⚠️  启动失败，跑 ccr serve 看前台输出排查"
    return 1
  fi
}

run_claude_code() {
  ensure_ccr || return 1
  ccr code        # 对应 CCR 里名为 code 的档案
}

run_hermes_agent() {
  (
    export ANTHROPIC_BASE_URL
    export ANTHROPIC_AUTH_TOKEN
    export ANTHROPIC_MODEL
    export API_TIMEOUT_MS
    hermes agent
  )
}

cmd_status() {
  echo "───────────────"
  if server_running; then
    echo " 模型服务: 🟢 $(basename "$(current_model)")  端口: $PORT"
  else
    echo " 模型服务: ⚪ 未运行"
  fi
  if ccr_running; then
    echo " CCR 网关: 🟢 端口 $CCR_PORT"
  else
    echo " CCR 网关: ⚪ 未运行"
  fi
  echo "───────────────"
}

# ===================== 非交互快捷命令 =====================
if [ $# -gt 0 ]; then
  case "$1" in
    start)
      alias="${2:-27b}"
      valid=0
      for m in "${MODEL_ALIASES[@]}"; do [ "$alias" = "$m" ] && valid=1; done
      if [ "$valid" != 1 ]; then
        echo "❌ 未知模型: $alias（可选: ${MODEL_ALIASES[*]}）"; exit 1
      fi
      if server_running; then
        echo "ℹ️  模型服务已在跑: $(basename "$(current_model)")"
      else
        start_server "$alias"
      fi
      ensure_ccr || true
      echo ""
      echo "🎉 就绪。客户端: ccr code / codex / hermes agent"
      cmd_status
      ;;
    stop)
      ccr stop >/dev/null 2>&1 || true
      stop_server
      ;;
    restart)
      ccr stop >/dev/null 2>&1 || true
      pkill -f "optiq serve" 2>/dev/null || true
      sleep 1
      exec "$0" start "${2:-}"
      ;;
    status)
      cmd_status
      ;;
    log)
      tail -f "$LOG_DIR/optiq.log"
      ;;
    *)
      echo "用法: $0 [start [27b|35b|gemma] | stop | restart | status | log]"
      exit 1
      ;;
  esac
  exit 0
fi

# ===================== 交互面板 =====================
while true; do
  echo ""
  echo "================ 本地 AI 服务面板 ================"
  if server_running; then
    echo " 模型服务: 🟢 $(basename "$(current_model)")  端口: $PORT"
  else
    echo " 模型服务: ⚪ 未运行"
  fi
  if ccr_running; then
    echo " CCR 网关: 🟢 端口 $CCR_PORT"
  else
    echo " CCR 网关: ⚪ 未运行（仅 Claude Code 需要）"
  fi
  echo "------------------------------------------------"
  echo " 1) 启动服务（选模型）     5) 进入 Claude Code (CCR桥)"
  echo " 2) 切换模型               6) 进入 Hermes agent"
  echo " 3) 停止服务               7) 查看实时日志"
  echo " 4) 查看状态               0) 退出（服务保持后台）"
  echo "================================================"
  read -rp "选择: " choice

  case $choice in
    1)
      a=$(pick_model) && start_server "$a"
      ;;
    2)
      switch_server
      ;;
    3)
      stop_server
      ;;
    4)
      "$SCRIPT_DIR/switch-model.sh" status
      ;;
    5)
      if server_running; then run_claude_code
      else echo "❌ 服务未启动，请先选 1"; fi
      ;;
    6)
      if server_running; then run_hermes_agent
      else echo "❌ 服务未启动，请先选 1"; fi
      ;;
    7)
      echo "（Ctrl+C 退出查看，不影响服务）"; sleep 1
      tail -f "$LOG_DIR/optiq.log"
      ;;
    0)
      echo "👋 面板退出，后台服务保持运行"; exit 0
      ;;
    *)
      echo "❌ 无效输入"
      ;;
  esac
done