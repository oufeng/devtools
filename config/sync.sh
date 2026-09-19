#!/bin/zsh
# 用法: ./config/sync.sh [commit message]
# 把 3 个 agent + oMLX 的生效配置复制进仓库; 给了 commit message 就顺手提交
# oMLX settings.json 含密钥，复制后强制打码，打码失败直接退出
set -e
cd "$(dirname $0)/.."
cp ~/.codex/config.toml            config/codex/config.toml
cp ~/.config/opencode/opencode.json config/opencode/opencode.json
cp ~/.claude/settings.json         config/claude/settings.json
cp ~/.omlx/settings.json        config/omlx/settings.json
cp ~/.omlx/model_settings.json  config/omlx/model_settings.json
cp ~/.omlx/model_profiles.json  config/omlx/model_profiles.json
cp ~/.omlx/global_templates.json config/omlx/global_templates.json
sed -i '' -E 's/("api_key": ")[^"]*(")/\1REDACTED\2/; s/("secret_key": ")[^"]*(")/\1REDACTED\2/' config/omlx/settings.json
if grep -qE 'sk-omlx-|"secret_key": "[0-9a-f]{16,}"' config/omlx/settings.json; then
  echo "错误: settings.json 密钥打码失败，已中止" >&2
  exit 1
fi
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
