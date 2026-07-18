# 本地 OptiQ 模型安装与启动

## 1. 装工具（只需一次）

```bash
pip install -U mlx-lm mlx-optiq huggingface_hub
```

## 2. 下载模型（约 23GB，只需一次）

```bash
caffeinate -i hf download mlx-community/Qwen3.6-35B-A3B-OptiQ-4bit --local-dir ~/Developer/models/Qwen3.6-35B-A3B-OptiQ-4bit
caffeinate -i hf download mlx-community/Qwen3.6-27B-OptiQ-4bit --local-dir ~/Developer/models/Qwen3.6-27B-OptiQ-4bit
caffeinate -i hf download mlx-community/gemma-4-31B-it-OptiQ-4bit --local-dir ~/Developer/models/gemma-4-31B-it-OptiQ-4bit
caffeinate -i hf download mlx-community/gemma-4-31B-it-qat-OptiQ-4bit --local-dir ~/Developer/models/gemma-4-31B-it-qat-OptiQ-4bit
```

## 3. 启动服务

> **推荐日常使用 Qwen3.6-27B**，速度 & 质量平衡较好。

```bash
# Qwen3.6-27B（推荐）
optiq serve --model ~/Developer/models/Qwen3.6-27B-OptiQ-4bit --mtp --port 8080

# Qwen3.6-35B-A3B (MoE，更强但更慢)
optiq serve --model ~/Developer/models/Qwen3.6-35B-A3B-OptiQ-4bit --mtp --port 8080

# Gemma 4 31B
optiq serve --model ~/Developer/models/gemma-4-31B-it-OptiQ-4bit --mtp --port 8080

# Gemma 4 31B (QAT 量化)
optiq serve --model ~/Developer/models/gemma-4-31B-it-qat-OptiQ-4bit --mtp --port 8080
```

更便捷的方式：直接用 `switch-model.sh` 一键切换。

## 4. 配置 Codex CLI 使用本地模型

```bash
mkdir -p ~/.codex
cat > ~/.codex/config.toml << 'EOF'
model = "local_mlx"
model_provider = "optiq"
model_context_window = 131072
model_max_output_tokens = 32768

[model_providers.optiq]
name = "Local OptiQ"
base_url = "http://127.0.0.1:8080/v1"
wire_api = "responses"
requires_openai_auth = false
EOF

cat ~/.codex/config.toml    # 亲眼确认内容写进去了
```
