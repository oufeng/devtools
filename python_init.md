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

## 第四步：创建虚拟环境（项目隔离）

```bash
# 在项目目录下创建独立环境（默认用最新安装的版本）
uv venv myenv

# 也可指定 Python 版本
uv venv myenv --python 3.12

# 激活环境
source myenv/bin/activate

# 退出环境
deactivate
```

> 激活后终端提示符前会出现 `(myenv)` 字样。删除环境 = 直接删除文件夹：`rm -rf myenv`。

## 第五步：安装与管理包（替代 pip）

⚠️ 以下命令都需**先激活虚拟环境**再执行——uv 故意禁止往系统 Python 里装包，这是保护机制。

```bash
uv pip install requests        # 装包
uv pip list                    # 查看已安装的包
uv pip show requests           # 查看某个包的详情
uv pip install -U requests     # 升级包
uv pip uninstall requests      # 卸包
```

## 日常维护

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
| 安装包 | `pip install xxx` | `uv pip install xxx` |
| 查看包列表 | `pip list` | `uv pip list` |
| shell 配置 | 需写 3 行到 `~/.zshrc` | **不需要** |

---