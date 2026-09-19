#!/bin/bash
# config.sh — 本地开发工具集共享配置（oMLX 版）
# 用法: source "$(dirname "$0")/config.sh"
#
# 所有值都可通过环境变量覆盖，例如：
#   OMLX_PORT=9000 ./switch-model.sh status

# oMLX 服务（托管后台服务，主配置在 ~/.omlx/settings.json）
: "${OMLX_HOST:=127.0.0.1}"
: "${OMLX_PORT:=8000}"
: "${OMLX_SETTINGS:="$HOME/.omlx/settings.json"}"
: "${OMLX_LOG:="$HOME/.omlx/logs/server.log"}"

# 模型存放目录（settings.json 的 model_dirs，子目录名 = model_id）
: "${MODELS_DIR:="$HOME/Developer/models"}"

# 等待服务就绪/释放端口的最长秒数
: "${STOP_TIMEOUT:=30}"

# 模型清单（别名 → 模型目录名 = omlx model_id）
: "${MODEL_OQ4E:=Qwen3.8-27B-oQ4e-mtp}"
: "${MODEL_8BIT:=Qwen3.8-27B-8bit}"

# Codex CLI 配置（switch-model.sh 会更新其中的 model 行）
: "${CODEX_CONFIG:="$HOME/.codex/config.toml"}"

# ---------- oMLX 辅助函数（各脚本共享） ----------

# 从 settings.json 读取 API key
omlx_api_key() {
  python3 -c 'import json,sys
try:
    print(json.load(open(sys.argv[1])).get("auth", {}).get("api_key", ""))
except Exception:
    pass' "$OMLX_SETTINGS" 2>/dev/null
}

# 服务是否存活（/v1/models 能通即存活）
omlx_up() {
  curl -s -o /dev/null --connect-timeout 2 \
    -H "Authorization: Bearer $(omlx_api_key)" \
    "http://${OMLX_HOST}:${OMLX_PORT}/v1/models"
}

# 已加载模型 id 列表（每行一个）
omlx_model_ids() {
  omlx_up || return 1
  curl -s -H "Authorization: Bearer $(omlx_api_key)" \
    "http://${OMLX_HOST}:${OMLX_PORT}/v1/models" \
    | python3 -c 'import json,sys
for m in json.load(sys.stdin).get("data", []):
    print(m["id"])' 2>/dev/null
}
