# devtools

个人开发工具集，包含日常开发环境的配置与自动化脚本。

## 文件说明

| 文件 | 用途 |
|---|---|
| `.zshrc` | Oh My Zsh 配置（主题、插件、别名） |
| `mihomo-setup.sh` | macOS 上一键部署 Mihomo (Clash Meta) 代理 |
| `switch-model.sh` | 一键切换本地 OptiQ 模型服务 |
| `model.md` | 本地 OptiQ 模型安装与启动指南 |
| `python_init.md` | 使用 uv 管理 Python 环境的教程 |

## 快速入门

### 代理部署
```bash
bash mihomo-setup.sh "你的Clash订阅链接"
```

### 切换本地模型
```bash
./switch-model.sh 27b     # Qwen3.6-27B
./switch-model.sh 35b     # Qwen3.6-35B-A3B (MoE)
./switch-model.sh gemma   # Gemma 4 31B (QAT)
./switch-model.sh status  # 查看当前运行状态
```

### Python 环境
参考 `python_init.md`，使用 uv 快速搭建 Python 开发环境。
