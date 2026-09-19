#!/bin/zsh
# mattpocock/skills 一键更新: 拉上游 + 重建 3 个 agent 的 symlink
# 用法: ./skills/update.sh
set -e
cd "$(dirname $0)"
REPO=mattpocock
# 要安装的类别(对应上游 skills/ 下的子目录), 想加 in-progress/misc 在这里加
CATEGORY_DIRS=(engineering productivity)

# 1) 拉上游
cd $REPO
git pull --ff-only
REV=$(git rev-parse --short HEAD)
DATE=$(git log -1 --format=%cd --date=short)
cd ..
printf '%s' "$REV" > mattpocock-revision.txt

# 2) 重建 symlink
install_links() {
  local dest=$1 created=0 skipped=0 name link
  mkdir -p "$dest"
  for cat in $CATEGORY_DIRS; do
    for d in $REPO/skills/$cat/*/; do
      [ -f "$d/SKILL.md" ] || continue
      name=$(basename $d)
      link="$dest/$name"
      if [ -L "$link" ]; then
        ln -sfn "$PWD/$d" "$link"
      elif [ -e "$link" ]; then
        echo "  ! $dest: 跳过 $name (已存在非 symlink 条目, 未覆盖)"
        skipped=$((skipped+1))
      else
        ln -s "$PWD/$d" "$link"
        created=$((created+1))
      fi
    done
  done
  echo "$dest: 新增 $created, 跳过 $skipped"
}

echo "== 重建 symlink (源: $PWD/$REPO) =="
install_links "$HOME/.codex/skills"    # Codex
install_links "$HOME/.claude/skills"   # Claude Code; opencode 也会读这个目录

echo
echo "上游版本: $REV ($DATE)"
echo "已更新 mattpocock-revision.txt, 可 git add 提交以记录所用版本"
echo
cat <<'GUIDE'
== 首次配置 (每个 repo 跑一次, 已配过可忽略) ==
setup-matt-pocock-skills 会交互式配置:
  1. issue tracker: GitHub / Linear / 本地文件
  2. triage 用的标签
  3. 生成的文档存放位置
在目标 repo 里对任一 agent 说:
  - Codex / opencode:  "run setup-matt-pocock-skills"
  - Claude Code:       /setup-matt-pocock-skills
triage / to-tickets / to-spec 等 skill 依赖这份配置。
GUIDE
