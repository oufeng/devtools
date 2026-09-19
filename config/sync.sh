#!/bin/zsh
# 用法: ./config/sync.sh [commit message]
# 把 3 个 agent + oMLX 的生效配置复制进仓库; 给了 commit message 就顺手提交
set -e
cd "$(dirname $0)/.."
cp ~/.codex/config.toml            config/codex/config.toml
cp ~/.config/opencode/opencode.json config/opencode/opencode.json
cp ~/.claude/settings.json         config/claude/settings.json
cp ~/.omlx/model_settings.json  config/omlx/model_settings.json
git add config
if git diff --cached --quiet; then
  echo "配置无变化，无需提交"
else
  git diff --cached --stat
  if [ -n "$1" ]; then
    git commit -m "$1"
  else
    echo "已暂存改动，请自行 git commit"
  fi
fi
