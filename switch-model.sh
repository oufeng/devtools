#!/bin/bash
# 用法: ./switch-model.sh {27b|35b|gemma}
pkill -f "optiq serve" 2>/dev/null || true
while lsof -i :8080 >/dev/null 2>&1; do sleep 1; done   # 等端口释放

case "$1" in
  27b)   M=~/Developer/models/Qwen3.6-27B-OptiQ-4bit;    EXTRA="--mtp" ;;
  35b)   M=~/Developer/models/Qwen3.6-35B-A3B-OptiQ-4bit; EXTRA="--mtp" ;;
  gemma) M=~/Developer/models/gemma-4-31B-it-OptiQ-4bit;  EXTRA="" ;;
  *) echo "用法: $0 {27b|35b|gemma}"; exit 1 ;;
esac

exec optiq serve --model "$M" $EXTRA --port 8080