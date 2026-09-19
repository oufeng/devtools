# devtools

个人开发工具集，包含日常开发环境的配置与自动化脚本。

## 文件说明

| 文件 | 用途 |
|---|---|
| `.zshrc` | Oh My Zsh 配置（主题、插件、别名、PATH） |
| `config.sh` | 脚本共享配置（oMLX 端口、模型目录、API key 读取等） |
| `mihomo-setup.sh` | macOS 上一键部署 Mihomo (Clash Meta) 代理 |
| `switch-model.sh` | oMLX 服务管理 + 切换 Codex 默认模型 |
| `start_agent.sh` | 交互式本地 AI 服务面板（调用 switch-model.sh） |
| `model.md` | 本地 oMLX 模型安装与启动指南 |
| `python_init.md` | 使用 uv 管理 Python 环境的教程 |
| `arxiv_review.py` | arXiv 周报：抓论文 + 生成"顶会审稿人"prompt（cron 用） |
| `GMAIL_SETUP.md` | arXiv 周报定时任务说明 |

## 快速入门

### 代理部署
```bash
bash mihomo-setup.sh "你的Clash订阅链接"
```
> 脚本会自动检测当前活跃的网络服务（Wi-Fi / 有线 / 热点）并设置系统代理。

### 本地模型服务（oMLX）
```bash
omlx start                    # 启动多模型后台服务（端口 8000）
./switch-model.sh status      # 查看服务 + Codex 默认模型
./switch-model.sh oq4e        # Codex 切到 Qwen3.8-27B-oQ4e-mtp（MTP 加速）
./switch-model.sh 8bit        # Codex 切到 Qwen3.8-27B-8bit
```

oMLX 是多模型服务：一个后台进程托管 `~/Developer/models` 下全部模型
（LRU 内存管理），切换模型不用重启服务。客户端接入：

```bash
omlx launch codex             # Codex CLI
omlx launch claude            # Claude Code（无需 CCR 中转）
omlx launch hermes            # Hermes agent
```

### 交互式管理面板
```bash
./start_agent.sh
```
支持启动/停止/切换模型、进入 Claude Code / Hermes agent、查看实时日志。

### Python 环境
参考 `python_init.md`，使用 uv 快速搭建 Python 开发环境。

## 自定义配置

编辑 `config.sh` 即可修改默认端口、模型目录、模型别名等，无需改动脚本主体，
也支持环境变量覆盖，例如：
```bash
OMLX_PORT=9000 ./switch-model.sh status
```

| 变量 | 默认值 | 说明 |
|---|---|---|
| `OMLX_HOST` / `OMLX_PORT` | `127.0.0.1` / `8000` | oMLX 服务地址 |
| `MODELS_DIR` | `~/Developer/models` | 模型存放目录（子目录名 = model_id） |
| `OMLX_SETTINGS` | `~/.omlx/settings.json` | oMLX 主配置（读 API key 用） |
| `OMLX_LOG` | `~/.omlx/logs/server.log` | 服务日志 |
| `CODEX_CONFIG` | `~/.codex/config.toml` | 切换模型时更新的文件 |
| `MODEL_OQ4E` / `MODEL_8BIT` | — | 模型别名 → 目录名 |
