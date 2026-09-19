# ArXiv 论文周报 - 顶会严苛审稿人版

## 配置完成

- **定时任务**：每周一上午 9:00 自动执行
- **报告位置**：`/tmp/arxiv_weekly_review.txt`
- **查看方式**：`cat /tmp/arxiv_weekly_review.txt`

## 当前限制

Gmail SMTP 无法通过代理连接，已改为本地保存报告。

### 未来可选推送方案

1. **Telegram** — 需要能收到验证码
2. **企业微信** — 需要管理员权限
3. **QQ/163 邮箱 SMTP** — 国内可用，可替换 Gmail
4. **微信** — 个人号有风险，不推荐

### 手动运行

```bash
cd /Users/jeff/Developer/devtools && .venv/bin/python arxiv_review.py
```

---

## 如果你想配置邮件推送

