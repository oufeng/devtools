在MacBook上管理Python，最专业且推荐的方式是使用版本管理工具 pyenv 和虚拟环境 [uv](https://github.com/astral-sh/uv) 或 Python 自带的 venv。这能避免破坏Mac系统自带的Python，并允许你同时运行多个不同的Python版本。 [1, 2, 3, 4] 
请按以下步骤配置：
## 第一步：安装必备工具
打开“终端” (Terminal) 并安装包管理器 [Homebrew](https://brew.sh/)：
/bin/bash -c "$(curl -fsSL https://githubusercontent.com)"
## 第二步：安装并配置 pyenv (多版本管理)

   1. 安装 pyenv：在终端运行 brew install pyenv。
   2. 配置环境变量（将以下命令复制到终端以写入配置文件）：
   
   echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
   echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
   echo 'eval "$(pyenv init -)"' >> ~/.zshrc
   source ~/.zshrc
   
   [4] 

## 第三步：安装与切换 Python

   1. 安装指定版本：例如安装 Python 3.12.3，输入 pyenv install 3.12.3。
   2. 设置全局版本：输入 pyenv global 3.12.3。
   3. 验证版本：输入 python --version 确认已切换。 [1, 5] 

## 第四步：创建虚拟环境 (项目隔离)

   1. 在你的项目目录下，输入命令来创建独立的环境：
   python -m venv myenv
   2. 激活虚拟环境：
   source myenv/bin/activate
   3. 安装库后，退出环境只需输入：
   deactivate