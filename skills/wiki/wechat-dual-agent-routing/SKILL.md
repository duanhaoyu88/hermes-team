---
name: wechat-dual-agent-routing
description: Set up dual Hermes agents (default + wiki-agent) with single WeChat bot entry point, persistent tmux collaboration, and AGENTS.md routing rules. Handles WeChat's one-bot-only limitation.
version: 1.0.0
author: auto-generated
---

# WeChat Dual-Agent Routing

## Problem

WeChat iLinkAI only allows **one bot connection at a time**. If two Hermes profiles both configure WeChat, only the last one to connect stays online — the other gets silently disconnected.

## Architecture

```
用户 WeChat
  │
  ▼
default agent (WeChat gateway)   ← 唯一 WeChat 入口
  │
  │  tmux send-keys + capture-pane
  ▼
wiki-agent (tmux 常驻会话)        ← 无 WeChat，专注知识库
```

- **Default**: Runs WeChat gateway (the only profile that talks to WeChat)
- **Wiki-agent**: Runs in a persistent tmux session, no WeChat gateway
- **Communication**: Default uses `tmux send-keys` to send tasks, `tmux capture-pane` to read results
- **Routing**: AGENTS.md loaded by default profile routes KB questions to wiki-agent

## Setup Steps

### 1. Disable wiki-agent's WeChat config

```bash
# Comment out all WEIXIN_* lines in wiki-agent's .env
sed -i 's/^WEIXIN_/#WEIXIN_/' /home/duanhaoyu/.hermes/profiles/wiki-agent/.env
```

### 2. Restart gateway

```bash
hermes gateway restart
```

### 3. Start wiki-agent in persistent tmux

```bash
tmux new-session -d -s wiki-agent -x 132 -y 40 'hermes --profile wiki-agent'
sleep 10  # wait for startup
tmux capture-pane -t wiki-agent -p | tail -5  # verify ready
```

### 4. Create AGENTS.md with routing rules

Create `~/.hermes/AGENTS.md` (or `<profile_dir>/AGENTS.md`) with:

```markdown
# WeChat 消息路由规则

## 路由判断
- **知识库类问题** → tmux send-keys + capture-pane 转发给 wiki-agent
- **非知识库问题** → 自己处理

## 通信协议
### 发消息给 wiki-agent
```bash
tmux send-keys -t wiki-agent '<问题>' Enter
```

### 读回复（等待 N 秒后）
```bash
sleep 15  # 根据复杂度调整
tmux capture-pane -t wiki-agent -p | tail -30
```

### 中断当前处理（wiki-agent 正在回复中）
```bash
tmux send-keys -t wiki-agent '' C-c
sleep 1
```

## 判断示例
| 消息 | 路由 |
|------|------|
| "查知识库里关于 TCP 的内容" | → wiki-agent |
| "写一个 FastAPI 接口" | default 自己处理 |
```
See the full example in the conversation that generated this skill.

### 5. Verify

```bash
# Check gateway status
hermes gateway status

# Check wiki-agent tmux
tmux capture-pane -t wiki-agent -p | tail -10

# Attach to wiki-agent for manual work
tmux attach -t wiki-agent
# Detach: Ctrl+B, D
```

## Recovery on WSL Restart

```bash
# Re-launch wiki-agent tmux after WSL reboot
tmux new-session -d -s wiki-agent 'hermes --profile wiki-agent'
```

## Pitfalls

- **WeChat only-one-bot**: This is a WeChat server-side limitation. Only one profile can have `WEIXIN_*` uncommented in its .env at any time.
- **AGENTS.md location**: Put it in the profile directory (`~/.hermes/profiles/<name>/AGENTS.md`) or the root `~/.hermes/AGENTS.md` for profile-specific vs all-profiles loading.
- **tmux output parsing**: `capture-pane` gets ALL visible output, including the prompt and previous messages. Use `tail -20` or grab the last response block.
- **Timing**: The default agent needs to `sleep` after sending a message to wiki-agent. Simple queries ~15s, complex tasks ~30-60s. Too short → get stale output. Too long → user waits.
- **Interrupt handling**: If wiki-agent is mid-response and a new query comes in, send `C-c` first, then the new message. Otherwise both messages queue up.
- **No persistent-wiki-agent needed for simple use**: For fire-and-forget KB queries, `hermes --profile wiki-agent chat -q "<question>"` (one-shot) is simpler and avoids tmux complexity. Only use tmux persistence when wiki-agent needs multi-turn context.

## Alternative: API Server Gateway (Cleaner but More Setup)

Instead of tmux, run wiki-agent with `API_SERVER_ENABLED=true` and communicate via HTTP:
- default agent: POST to wiki-agent's API endpoint
- wiki-agent: respond with JSON

Pro: No tmux, no output parsing, no timing issues
Con: Requires configuring API server, authentication, port management

## Key Commands Reference

| Action | Command |
|--------|---------|
| 启动 wiki-agent tmux | `tmux new-session -d -s wiki-agent 'hermes -p wiki-agent'` |
| 查看 wiki-agent 状态 | `tmux capture-pane -t wiki-agent -p \| tail -10` |
| 发消息给 wiki-agent | `tmux send-keys -t wiki-agent '查询...' Enter` |
| 中断 wiki-agent | `tmux send-keys -t wiki-agent '' C-c` |
| 进入 wiki-agent 交互 | `tmux attach -t wiki-agent` (Ctrl+B,D 脱离) |
| 重启 gateway | `hermes gateway restart` |
| 查看 logs | `less ~/.hermes/logs/gateway.log` |
