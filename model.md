# 1. 装工具（只需一次）
pip install -U mlx-lm mlx-optiq huggingface_hub

# 2. 下载模型（约 23GB，只需一次）
caffeinate -i hf download mlx-community/Qwen3.6-35B-A3B-OptiQ-4bit --local-dir ~/Developer/models/Qwen3.6-35B-A3B-OptiQ-4bit
caffeinate -i hf download mlx-community/Qwen3.6-27B-OptiQ-4bit --local-dir ~/Developer/models/Qwen3.6-27B-OptiQ-4bit
caffeinate -i hf download mlx-community/gemma-4-31b-it-8bit --local-dir ~/Developer/models/gemma-4-31b-it-8bit

# 3. 每次想用就启动服务
optiq serve --model ~/Developer/models/Qwen3.6-35B-A3B-OptiQ-4bit --mtp --port 8080
optiq serve --model ~/Developer/models/Qwen3.6-27B-OptiQ-4bit --mtp --port 8080
optiq serve --model ~/Developer/models/gemma-4-31b-it-8bit --mtp --port 8080

```bash
mkdir -p ~/.codex
cat > ~/.codex/config.toml << 'EOF'
model = "qwen3.6-27b"
model_provider = "optiq"
model_context_window = 131072

[model_providers.optiq]
name = "Local OptiQ"
base_url = "http://127.0.0.1:8080/v1"
wire_api = "responses"
requires_openai_auth = false
EOF

cat ~/.codex/config.toml    # 亲眼确认内容写进去了
```