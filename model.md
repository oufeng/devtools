# 1. 装工具（只需一次）
pip install -U mlx-lm mlx-optiq huggingface_hub

# 2. 下载模型（约 23GB，只需一次）
hf download mlx-community/Qwen3.6-35B-A3B-OptiQ-4bit --local-dir ~/Developer/models/Qwen3.6-35B-A3B-OptiQ-4bit
hf download mlx-community/Qwen3.6-27B-OptiQ-4bit --local-dir ~/Developer/models/Qwen3.6-27B-OptiQ-4bit
hf download mlx-community/gemma-4-31b-it-8bit --local-dir ~/Developer/models/gemma-4-31b-it-8bit

# 3. 每次想用就启动服务
optiq serve --model ~/Developer/models/Qwen3.6-35B-A3B-OptiQ-4bit --mtp --port 8080
optiq serve --model ~/Developer/models/Qwen3.6-27B-OptiQ-4bit --mtp --port 8080
optiq serve --model ~/Developer/models/gemma-4-31b-it-8bit --mtp --port 8080