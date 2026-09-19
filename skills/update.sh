#!/bin/zsh
# skills 一键更新: 拉全部上游仓库 + 重建 ~/.codex/skills 与 ~/.claude/skills 的 symlink
# 用法: ./skills/update.sh
set -e
cd "$(dirname $0)"

DESTS=("$HOME/.codex/skills" "$HOME/.claude/skills")

# 仓库表: dir|srcdirs(空格分隔; 每项是 skill 目录本身, 或包含多个 skill 的父目录; "."=repo 根)|mode(all|only|except)|名单(空格分隔)
REPOS=(
  "mattpocock|skills/engineering skills/productivity|all|"
  "anthropics/skills|skills|except|skill-creator"
  "addyosmani/agent-skills|skills|only|api-and-interface-design browser-testing-with-devtools ci-cd-and-automation code-simplification constraint-driven-development context-engineering deprecation-and-migration documentation-and-adrs doubt-driven-development frontend-ui-engineering git-workflow-and-versioning incremental-implementation observability-and-instrumentation performance-optimization security-and-hardening shipping-and-launch source-driven-development"
  "nextlevelbuilder/ui-ux-pro-max-skill|.claude/skills|all|"
  "JuliusBrussee/caveman|skills|only|caveman cavecrew caveman-commit caveman-compress caveman-explore caveman-help caveman-review investigate-first lean-build migration safe-refactor surgical-patch verify-and-stop"
  "Leonxlnx/taste-skill|skills|except|taste-skill-v1"
  "tt-a1i/archify|archify .agents/skills/archify-review|all|"
  "blader/humanizer|.|all|"
)

# dir -> git url (仅用于目录缺失时重新 clone)
repo_url() {
  case $1 in
    mattpocock) echo https://github.com/mattpocock/skills.git ;;
    *) echo "https://github.com/$1" ;;
  esac
}

install_links() {
  setopt localoptions null_glob
  local dest=$1 dir=$2 srcdirs=$3 mode=$4 list=$5
  local created=0 skipped=0 name link s d
  mkdir -p "$dest"
  for d in ${=srcdirs}; do
    local skill_dirs=()
    if [ -f "$dir/$d/SKILL.md" ]; then
      # srcdir 本身就是一个 skill 目录
      skill_dirs=("$dir/$d")
    else
      # srcdir 是包含多个 skill 的父目录
      for s in "$dir/$d"/*/; do
        [ -f "$s/SKILL.md" ] && skill_dirs+=("$s")
      done
    fi
    for s in $skill_dirs; do
      [ -n "$s" ] || continue
      if [ "$d" = "." ]; then name=$(basename $dir); s=$dir
      else name=$(basename $s); fi
      case $mode in
        only)   [[ " $list " == *" $name "* ]] || continue ;;
        except) [[ " $list " == *" $name "* ]] && continue ;;
      esac
      link="$dest/$name"
      if [ -L "$link" ]; then ln -sfn "$PWD/$s" "$link"
      elif [ -e "$link" ]; then echo "  ! $dest: 跳过 $name (已存在非 symlink 条目, 未覆盖)"; skipped=$((skipped+1))
      else ln -s "$PWD/$s" "$link"; created=$((created+1)); fi
    done
  done
  # 清理指向本 repo 但上游已删除的失效 symlink
  local l tgt
  for l in "$dest"/*; do
    [ -L "$l" ] || continue
    tgt=$(readlink "$l")
    case $tgt in
      "$PWD/$dir"|"$PWD/$dir"/*)
        [ -e "$l" ] || { rm "$l"; echo "  - $dest: 移除失效 $(basename $l)"; } ;;
    esac
  done
  echo "$dest <- $dir: 新增 $created, 跳过 $skipped"
}

for entry in $REPOS; do
  dir=${entry%%|*};   rest=${entry#*|}
  srcdirs=${rest%%|*}; rest=${rest#*|}
  mode=${rest%%|*};   list=${rest#*|}

  if [ ! -d "$dir/.git" ]; then
    echo "== clone $dir"
    mkdir -p "$(dirname $dir)"
    git clone --depth 1 "$(repo_url $dir)" "$dir"
  fi

  git -C "$dir" pull --ff-only
  rev=$(git -C "$dir" rev-parse --short HEAD)
  date=$(git -C "$dir" log -1 --format=%cd --date=short)
  printf '%s' "$rev" > "${dir/\//-}-revision.txt"
  echo "== $dir @ $rev ($date)"

  for dest in $DESTS; do
    install_links "$dest" "$dir" "$srcdirs" "$mode" "$list"
  done
done

echo
echo "各仓库版本已写入 *-revision.txt, 可 git add 提交以记录所用版本"
echo
cat <<'GUIDE'
== 首次配置 (mattpocock 系, 已配过可忽略) ==
setup-matt-pocock-skills 会交互式配置:
  1. issue tracker: GitHub / Linear / 本地文件
  2. triage 用的标签
  3. 生成的文档存放位置
在目标 repo 里对任一 agent 说:
  - Codex / opencode:  "run setup-matt-pocock-skills"
  - Claude Code:       /setup-matt-pocock-skills
triage / to-tickets / to-spec 等 skill 依赖这份配置。
GUIDE
