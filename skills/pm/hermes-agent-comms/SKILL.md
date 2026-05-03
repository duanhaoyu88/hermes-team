---
name: hermes-agent-comms
description: Hermes 多 Agent 通信协议 — 拉模式 + status 文件 + 启动验证 + 热重启
version: 1.4
---

# Hermes Agent 通信协议 v1.4

> 所有 agent 间通信遵循此协议。本次会话新增：启动验证流程、热重启、并发控制。

## 1. Agent 启动验证（CRITICAL — 防消息丢失）

**重启后必须完成以下步骤才能发消息：**

```bash
# Step 1: 确认进程已起
herm status                    # 4 个 agent 全部 ✅ 运行中

# Step 2: 等初始化（30s，wiki-agent ~25s 加载 llm-wiki）
sleep 30

# Step 3: 逐个确认就绪
for s in pm qa coco wiki; do
  tmux capture-pane -t ${s}-agent -p -S -3 | grep '❯' && echo "$s ready" || echo "$s NOT READY"
done
```
> 看到 `agent-name ❯` 才算就绪。看到 `Initializing` 或 `⚕` 继续等。

## 2. 发送消息

**必须用 `herm {agent}-ask`，不用裸 tmux send-keys（已验证可能丢消息）：**

```bash
herm qa-ask "[sender-session] 消息内容"
herm coco-ask "[sender-session] 消息内容"
herm wiki-ask "[sender-session] 消息内容"
herm pm-ask "[sender-session] 消息内容"
```

**消息格式**：`[sender] 完整上下文`，一条包全部，不拆多行。

## 3. 并发控制

⚠️ **不要同时向多个 agent 发消息**——会互相打断。逐个发，等回复再发下一个。

## 4. 读取回复（拉模式）

```bash
tmux capture-pane -t {target-session} -p -S -20
```

> Agent 在自己的终端输出是默认行为，不会主动 send-keys 回传。这是拉模式，不是推模式。

## 5. 完成通知（推模式）

Agent 完成后写状态文件：
```json
{"agent":"qa","task_id":6,"status":"needs_review","time":"ISO8601","summary":"..."}
```
文件路径：`/tmp/hermes-{agent}-{task_id}.status`

## 6. 配置变更后热重启

```bash
herm reload   # Ctrl+C→exit→重启，不断 tmux session
```

改完 AGENTS.md/SOUL.md/skills 后必须 reload 生效。reload 后回到 §1 启动验证。

## 7. Session 地址簿

| Agent | Session | 发送命令 |
|-------|---------|---------|
| PM | pm-agent | `herm pm-ask "[sender] 消息"` |
| QA | qa-agent | `herm qa-ask "[sender] 消息"` |
| Coco | coco-agent | `herm coco-ask "[sender] 消息"` |
| Wiki | wiki-agent | `herm wiki-ask "[sender] 消息"` |

## 8. 状态文件速查

| 文件 | 用途 |
|------|------|
| `/tmp/hermes-{agent}-{task_id}.status` | agent 完成通知 |
| `/tmp/hermes-pm-{task_id}.status` | PM 汇总通知 |
| `/home/duanhaoyu/.hermes/events.jsonl` | watcher 事件流 |
| `/home/duanhaoyu/.hermes/projects/{project}-{task_id}.task` | 任务状态机 |

## 9. 禁止事项

- ❌ agent 没就绪就发消息（必丢）
- ❌ 同时向多个 agent 发消息（互相打断）
- ❌ 用裸 tmux send-keys（用 herm *-ask）
- ❌ 消息不带 `[sender]` 前缀
- ❌ agent 完成后不写 status 文件

## 10. 实时复盘

遇卡点立即记录：
```bash
echo "[$(date +%H:%M)] 卡点描述" >> /tmp/hermes-retro-notes.md
```
