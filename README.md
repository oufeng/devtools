# devtools

个人开发工具集，包含日常开发环境的配置与自动化脚本。

## 文件说明

| 文件 | 用途 |
|---|---|
| `.zshrc` | Oh My Zsh 配置（主题、插件、别名、PATH） |
| `config.sh` | 脚本共享配置（模型目录、端口、日志路径等） |
| `mihomo-setup.sh` | macOS 上一键部署 Mihomo (Clash Meta) 代理 |
| `switch-model.sh` | 一键切换本地 OptiQ 模型服务 |
| `start_agent.sh` | 交互式本地 AI 服务面板（调用 switch-model.sh） |
| `model.md` | 本地 OptiQ 模型安装与启动指南 |
| `python_init.md` | 使用 uv 管理 Python 环境的教程 |

## 快速入门

### 代理部署
```bash
bash mihomo-setup.sh "你的Clash订阅链接"
```
> 脚本会自动检测当前活跃的网络服务（Wi-Fi / 有线 / 热点）并设置系统代理。

### 切换本地模型
```bash
./switch-model.sh 27b     # Qwen3.6-27B
./switch-model.sh 35b     # Qwen3.6-35B-A3B (MoE)
./switch-model.sh gemma   # Gemma 4 31B (QAT)
./switch-model.sh status  # 查看当前运行状态
```

路径、端口等配置集中在 `config.sh`，也支持环境变量覆盖，例如：
```bash
PORT=8081 MODELS_DIR=/opt/models ./switch-model.sh 27b
```

### 交互式管理面板
```bash
./start_agent.sh
```
支持启动/切换/停止模型、进入 Claude Code / Hermes agent、查看实时日志。

### Python 环境
参考 `python_init.md`，使用 uv 快速搭建 Python 开发环境。

## 自定义配置

编辑 `config.sh` 即可修改默认路径、端口、模型别名等，无需改动脚本主体。

| 变量 | 默认值 | 说明 |
|---|---|---|
| `MODELS_DIR` | `~/Developer/models` | 模型存放目录 |
| `KV_DIR` | `~/Developer/models/kv` | KV cache 配置目录 |
| `PORT` | `8080` | optiq 服务端口 |
| `LOG_DIR` | `~/ai-logs` | 日志目录 |
| `OPTQ_VENV` | `~/.venvs/mlx` | 自动激活 optiq 的虚拟环境 |
| `MODEL_27B` / `MODEL_35B` / `MODEL_GEMMA` | — | 模型目录名 |
