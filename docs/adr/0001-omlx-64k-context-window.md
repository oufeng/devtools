# ADR-0001: oMLX 本机上下文窗口定为 64k

- Status: accepted
- Date: 2026-09-20

## Context

本机为 MacBook Pro M5 Pro / 48GB 内存，主模型 `Qwen3.8-27B-oQ4e-mtp`（turboquant 4-bit KV + MTP 已开启）。曾尝试 128k 上下文窗口（见提交 `14af04d`），后全局及各 agent（codex / opencode / claude）统一回退到 65536。

48GB 内存下的预算：27B oQ4e 权重约 15-16GB，hot cache 12GB，内存守卫 soft 0.85 / hard 0.95（约 41GB / 46GB）。128k KV 即使在 4-bit turboquant 下也会显著挤压系统余量，多 agent 并发时更紧张。

## Decision

- `max_context_window` 固定为 **65536**，各 agent 侧（opencode `context`、claude `CLAUDE_CODE_MAX_CONTEXT_TOKENS`）保持一致。
- `max_concurrent_requests` 设为 **1**：日常单 agent 使用，避免 KV 压力翻倍。
- 128k 仅在临时单并发长文档场景手动开启，不写进同步配置。

## Consequences

- 翻案需要显式理由（如换更大内存机型），修改时同步更新本 ADR。
- `config/sync.sh` 同步 oMLX 全部 4 个配置文件，`settings.json` 密钥强制打码，防止真实密钥入库。
