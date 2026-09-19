# 本地 oMLX 模型安装与启动

> 2026-09 更新：已从 optiq 迁移到 **oMLX**（Apple Silicon 多模型 LLM 服务）。
> 一个后台服务托管 `~/Developer/models` 下全部模型（LRU 内存管理），
> 切换模型**不需要重启服务**，客户端直接指定 model 即可。

## 1. 装工具（只需一次）

```bash
# oMLX：macOS app + CLI（CLI 在 ~/.omlx/bin/omlx，已软链到 /opt/homebrew/bin）
# 主配置: ~/.omlx/settings.json（端口 8000、模型目录、API key 等）

# 下载模型用 hf（uv tool 管理）
uv tool install huggingface_hub
```

## 2. 下载模型（只需一次）

模型放在 `~/Developer/models/<模型名>/`，**子目录名就是 omlx 的 model_id**。

```bash
# Qwen3.8-27B 8bit（约 27GB，高精度/多模态）
caffeinate -i hf download mlx-community/Qwen3.8-27B-8bit \
  --local-dir ~/Developer/models/Qwen3.8-27B-8bit

# Qwen3.8-27B OptiQ 4bit + MTP（约 15GB，日常编码主力，MTP 投机解码）
caffeinate -i hf download <oQ4e-mtp 的 HF 仓库> \
  --local-dir ~/Developer/models/Qwen3.8-27B-oQ4e-mtp
```

> 新增模型：下载进 `~/Developer/models/` 后，oMLX 自动发现，无需改配置。
> 每个模型的 thinking 预算 / MTP / 量化 KV 等参数在 oMLX app UI 或
> `~/.omlx/model_settings.json` 里按模型调整。

## 3. 启动服务

```bash
omlx start          # 托管后台服务（macOS app 管理，开机可自启）
omlx stop           # 停止
omlx restart        # 重启
omlx serve --port 8000   # 前台调试用（默认从 ~/.omlx/models 发现模型）
omlx diagnose menubar    # 排查安装/运行问题
```

更便捷的方式：直接用 `./switch-model.sh status` 看状态，
`./start_agent.sh` 开交互面板。

## 4. 客户端接入（无需 CCR 中转）

```bash
omlx launch codex                 # Codex CLI
omlx launch claude --model 8bit   # Claude Code（可配 opus/sonnet/haiku 三层）
omlx launch hermes                # Hermes agent
omlx launch list                  # 看支持哪些工具
```

### Codex CLI 手动配置（omlx launch codex 等价于）

```bash
mkdir -p ~/.codex
cat > ~/.codex/config.toml << 'TOMLEOF'
model_provider = "omlx"
model = "Qwen3.8-27B-oQ4e-mtp"
model_context_window = 131072
model_max_output_tokens = 32768
disable_response_storage = true

[model_providers.omlx]
name = "oMLX"
base_url = "http://127.0.0.1:8000/v1"
wire_api = "responses"
experimental_bearer_token = "sk-omlx-xxxx"   # 见 ~/.omlx/settings.json → auth.api_key
TOMLEOF
```

## 5. 常用运维

```bash
tail -f ~/.omlx/logs/server.log      # 实时日志（MTP 命中率、cache 等都在里面）
./switch-model.sh oq4e|8bit          # 切换 Codex 默认模型
./switch-model.sh list               # 服务已加载的模型
omlx cluster                         # 分布式节点检查（多机场景）
```

## 与旧方案对照

| 需求 | 旧方案 (optiq) | 新方案 (oMLX) |
|---|---|---|
| 启动服务 | `optiq serve --model ... --port 8080` | `omlx start`（端口 8000，多模型） |
| 切换模型 | 杀进程 + 重启 | 客户端改 model，服务不动 |
| MTP 投机解码 | `--mtp` 参数 | 模型目录自带 MTP + model_settings 开关 |
| KV cache 优化 | 手动 `optiq kv-cache` 生成配置 | turboquant KV / paged SSD cache 内置 |
| Claude Code 接入 | CCR 中转 (3456) | `omlx launch claude` 直连 |
| Python 环境 | `~/.venvs/mlx` (optiq) | oMLX app 自带运行时，无需 venv |
