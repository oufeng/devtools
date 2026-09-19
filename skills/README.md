# mattpocock/skills 安装与跟踪

上游: https://github.com/mattpocock/skills (MIT)

## 结构

```
skills/
├── mattpocock/            # 上游完整 clone (gitignored, 历史在其自身 .git)
├── mattpocock-revision.txt # 当前安装的上游 commit, 由 update.sh 维护, 进 git
├── update.sh              # 一键更新
└── README.md
```

## 生效方式 (symlink, 单一来源)

| Agent | 目录 | 说明 |
|---|---|---|
| Codex | `~/.codex/skills/<skill>` | 官方文档明确支持 symlink |
| Claude Code | `~/.claude/skills/<skill>` | |
| opencode | 同 Claude | opencode 全局加载 `~/.claude/skills/` |

安装范围: 上游 `skills/engineering` + `skills/productivity` 全部 (25 个)。
调整范围: 改 `update.sh` 里的 `CATEGORY_DIRS` (可加 in-progress / misc)。

## 更新

```sh
./skills/update.sh
git add skills/mattpocock-revision.txt && git commit -m "bump mattpocock skills to <rev>"
```

查上游改动历史: `cd skills/mattpocock && git log --oneline`

## 备注

- 若某 agent 不跟随 symlink 导致 skill 不出现, 把该 agent 改成
  `rsync -a --delete` 复制模式即可 (改 update.sh 的 install_links)。
- 想还原上游原版: `cd skills/mattpocock && git checkout -- .` 后重跑 update.sh。
