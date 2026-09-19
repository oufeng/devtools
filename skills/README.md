# 第三方 skills 安装与跟踪

8 个上游仓库, 共 95 个 skill (mattpocock 25 + 新增 70), 全部 symlink 生效, 单一来源。

## 结构

```
skills/
├── <org>/<repo>/       # 上游完整 clone (gitignored, 历史在其自身 .git)
├── <org>-<repo>-revision.txt  # 当前安装的上游 commit, 由 update.sh 维护, 进 git
├── update.sh           # 一键更新 (多仓库表)
└── README.md
```

## 仓库清单

| 目录 | 上游 | revision | 说明 |
|---|---|---|---|
| `mattpocock/` | mattpocock/skills | mattpocock-revision.txt | 方法论系 (grilling/tdd/research 等 25 个) |
| `anthropics/skills/` | anthropics/skills | anthropics-skills-revision.txt | 官方 skill 库 18 个 (跳过 skill-creator, 与 Codex 内置冲突) |
| `addyosmani/agent-skills/` | addyosmani/agent-skills | addyosmani-agent-skills-revision.txt | 17 个 (跳过 8 个与 mattpocock 重叠的方法论) |
| `nextlevelbuilder/ui-ux-pro-max-skill/` | nextlevelbuilder/ui-ux-pro-max-skill | nextlevelbuilder-ui-ux-pro-max-skill-revision.txt | UI/UX 设计 7 个 |
| `JuliusBrussee/caveman/` | JuliusBrussee/caveman | JuliusBrussee-caveman-revision.txt | 13 个独立 skill (排除 7 个绑定 caveman.so 第三方网关的) |
| `Leonxlnx/taste-skill/` | Leonxlnx/taste-skill | Leonxlnx-taste-skill-revision.txt | 设计品味 12 个 (跳过 taste-skill-v1) |
| `tt-a1i/archify/` | tt-a1i/archify | tt-a1i-archify-revision.txt | 架构图 2 个 |
| `blader/humanizer/` | blader/humanizer | blader-humanizer-revision.txt | 去 AI 味 1 个 |

排除: obra/superpowers 等与 mattpocock 方法论竞争的仓库。

## 生效方式 (symlink)

| Agent | 目录 |
|---|---|
| Codex | `~/.codex/skills/<skill>` |
| Claude Code | `~/.claude/skills/<skill>` |
| opencode | 同 Claude (全局加载 `~/.claude/skills/`) |

## 更新

```sh
./skills/update.sh
git add skills && git commit -m "bump skills: <各仓库 rev>"
```

update.sh 仓库表格式: `dir|srcdirs|mode(all|only|except)|名单`, 增删 skill 改表即可。

## 备注

- 若某 agent 不跟随 symlink 导致 skill 不出现, 把该 agent 改成
  `rsync -a --delete` 复制模式即可 (改 update.sh 的 install_links)。
- 想还原上游原版: 进入对应 clone 目录 `git checkout -- .` 后重跑 update.sh。
