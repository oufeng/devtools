# Agent 配置跟踪

本目录镜像 3 个 coding agent 和 oMLX 本地服务的生效配置，用于跟踪改动历史（git log 可查每次变更）。

| 文件 | 生效位置 |
|---|---|
| `codex/config.toml` | `~/.codex/config.toml` |
| `opencode/opencode.json` | `~/.config/opencode/opencode.json` |
| `claude/settings.json` | `~/.claude/settings.json` |
| `omlx/model_settings.json` | `~/.omlx/model_settings.json` |

## 同步

改完任一 agent 的配置后运行：

```sh
./config/sync.sh "描述这次改了什么"   # 复制 + 提交
./config/sync.sh                     # 只复制 + 暂存，自己看 diff 再提交
```

注意：反向同步（仓库 → 生效位置）没有做，如需以仓库版本为准请手动 `cp` 回去。
