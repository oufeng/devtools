#!/bin/bash
# config.sh — 本地开发工具集共享配置
# 用法: source "$(dirname "$0")/config.sh"
#
# 所有值都可通过环境变量覆盖，例如：
#   MODELS_DIR=/opt/models ./switch-model.sh 27b

# 模型与 KV cache 根目录
: "${MODELS_DIR:="$HOME/Developer/models"}"
: "${KV_DIR:="${MODELS_DIR}/kv"}"

# optiq 服务端口
: "${PORT:=8080}"

: "${CCR_PORT:=3456}"


# 日志目录
: "${LOG_DIR:="$HOME/ai-logs"}"

# 自动激活 optiq 的 Python 虚拟环境路径（空字符串表示不自动激活）
: "${OPTQ_VENV:="$HOME/.venvs/mlx"}"

# 等待旧服务释放端口的最长秒数
: "${STOP_TIMEOUT:=30}"

# Claude Code 环境
: "${ANTHROPIC_BASE_URL:="http://127.0.0.1:${PORT}"}"
: "${ANTHROPIC_AUTH_TOKEN:="sk-optiq-local"}"
: "${ANTHROPIC_MODEL:="qwen3.6-27b"}"
: "${ANTHROPIC_SMALL_FAST_MODEL:="qwen3.6-27b"}"
: "${API_TIMEOUT_MS:=900000}"
: "${CLAUDE_CODE_MAX_OUTPUT_TOKENS:=32768}"

# 模型清单（别名 → 目录名）
# 目录名会拼接在 MODELS_DIR 后面
: "${MODEL_27B:=Qwen3.6-27B-OptiQ-4bit}"
: "${MODEL_35B:=Qwen3.6-35B-A3B-OptiQ-4bit}"
: "${MODEL_GEMMA:=gemma-4-31B-it-qat-OptiQ-4bit}"
