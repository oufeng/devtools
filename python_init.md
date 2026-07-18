# 在 MacBook 上用 uv 管理 Python

[uv](https://github.com/astral-sh/uv) 是 Astral 公司用 Rust 编写的 Python 管理工具，**一个工具同时替代 pyenv（版本管理）+ pip（包管理）+ venv（环境隔离）**，安装包的速度比 pip 快 10 倍以上，且无需修改任何 shell 配置文件。

## 第一步：安装 Homebrew（已安装可跳过）

打开"终端"（Terminal），运行：

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

验证：`brew --version` 能输出版本号即可。

## 第二步：安装 uv

```bash
brew install uv
```

验证：`uv --version`。
✅ 到此配置结束——不需要像 pyenv 那样往 `~/.zshrc` 写任何环境变量。

## 第三步：安装与管理 Python 版本（替代 pyenv）

```bash
# 安装指定版本（例如 3.12）
uv python install 3.12

# 查看所有版本（已安装的 + 可安装的）
uv python list

# 卸载某个版本（该版本下全局安装的包会一并删除）
uv python uninstall 3.12
```

> uv 管理的 Python 统一存放在 `~/.local/share/uv/python/`，与 macOS 系统自带的 `/usr/bin/python3` 完全隔离，互不影响。

## 第四步：创建项目（推荐工作流）

uv 推荐使用 `pyproject.toml` 管理依赖，无需手动创建和激活虚拟环境。

```bash
# 初始化新项目（自动生成 pyproject.toml）
uv init my-project

# 进入项目目录
cd my-project

# 添加依赖（uv 会自动创建并管理 .venv）
uv add requests

# 查看已安装的包
uv pip list

# 运行脚本（自动激活虚拟环境，无需手动 source）
uv run python main.py
```

> `uv run` 是核心用法——它会在合适的虚拟环境中执行命令，省去了手动 `source venv/bin/activate` 的步骤。

### 传统 venv 方式（仍可用）

如果你更习惯手动管理虚拟环境：

```bash
# 创建虚拟环境
uv venv myenv --python 3.12

# 激活环境
source myenv/bin/activate

# 安装包
uv pip install requests

# 退出环境
deactivate
```

## 第五步：日常维护

```bash
uv self update     # 升级 uv 自身
uv cache clean     # 清理下载缓存（缓存可能长到几 GB，建议定期清理）
```

## 与旧方案对照表

| 需求 | 旧方案 | uv 方案 |
|---|---|---|
| 安装 Python 版本 | `pyenv install 3.12` | `uv python install 3.12` |
| 切换/查看版本 | `pyenv global` / `pyenv versions` | `uv python list`（按环境指定，无需全局切换） |
| 创建虚拟环境 | `python -m venv myenv` | `uv venv myenv` |
| 安装包 | `pip install xxx` | `uv add xxx`（推荐）或 `uv pip install xxx` |
| 运行脚本 | `source venv/bin/activate && python main.py` | `uv run python main.py` |
| shell 配置 | 需写 3 行到 `~/.zshrc` | **不需要** |

---
