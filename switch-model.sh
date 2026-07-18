#!/bin/bash
# 用法: ./switch-model.sh {27b|35b|gemma}

# optiq kv-cache ~/Developer/models/Qwen3.6-27B-OptiQ-4bit \
#   --target-bits 5.0 --candidate-bits 4,8 \
#   -o ~/Developer/models/kv/qwen36_27b

# optiq kv-cache ~/Developer/models/Qwen3.6-35B-A3B-OptiQ-4bit \
#   --target-bits 5.0 --candidate-bits 4,8 \
#   -o ~/Developer/models/kv/qwen36_35b

pkill -f "optiq serve" 2>/dev/null || true
while lsof -i :8080 >/dev/null 2>&1; do sleep 1; done

case "$1" in
  27b) optiq serve --model ~/Developer/models/Qwen3.6-27B-OptiQ-4bit \
        --mtp --kv-config ~/Developer/models/kv/qwen36_27b/kv_config.json \
        --max-context auto --max-concurrent 8 --port 8080 ;;
  35b) optiq serve --model ~/Developer/models/Qwen3.6-35B-A3B-OptiQ-4bit \
        --mtp --kv-config ~/Developer/models/kv/qwen36_35b/kv_config.json \
        --max-context auto --max-concurrent 8 --port 8080 ;;
#   gemma) optiq serve --model ~/Developer/models/gemma-4-31B-it-OptiQ-4bit \
#         --drafter mlx-community/gemma-4-31B-it-assistant-bf16 \
#         --kv-config ~/Developer/models/gemma-4-31B-it-OptiQ-4bit/kv_config.json \
#         --max-context auto --port 8080 ;;
  gemma) optiq serve --model ~/Developer/models/gemma-4-31B-it-qat-OptiQ-4bit \
        --drafter google/gemma-4-31B-it-qat-q4_0-unquantized-assistant
        --kv-config ~/Developer/models/gemma-4-31B-it-qat-OptiQ-4bit/kv_config.json \
        --max-context auto --port 8080 ;;
  *) echo "用法: $0 {27b|35b|gemma}"; exit 1 ;;
esac