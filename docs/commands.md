# Hermes 命令速查

> 最后更新: 2026-05-02 | 适用: WSL Ubuntu

---

## herm — 多 Agent 管理

`herm` 是统一入口脚本 (`~/bin/herm`)，管理 wiki/qa/coco 三个 agent 的 tmux 生命周期。

### 状态

```bash
herm status          # 查看所有 agent 运行状态
```

输出示例:
```
┌─────────────────────────────────┐
│      Hermes 多 Agent 状态         │
├──────────┬──────────────────────┤
│ wiki-agent │ ✅ 运行中              │
│ qa-agent   │ ❌ 未运行              │
│ coco-agent │ ❌ 未运行              │
└──────────┴──────────────────────┘
```

### wiki-agent（知识库）

```bash
herm wiki-start       # 启动（首次 ~25s 初始化）
herm wiki-stop        # 停止
herm wiki-ask <问题>   # 发送任务指令
herm wiki-log [行数]   # 查看最近输出（默认 30 行）
herm wiki-attach      # 进入交互终端（Ctrl+B D 退出）
```

tmux session 名: `hermes-wiki`

### qa-agent（审查）

```bash
herm qa-start         # 启动
herm qa-stop          # 停止
herm qa-ask <问题>     # 发送审查指令
herm qa-log [行数]     # 查看最近输出
herm qa-attach        # 进入交互终端
```

模型: `deepseek-v4-flash`（轻量审查）
tmux session 名: `qa-agent`

### coco-agent（编码）

```bash
herm coco-start       # 启动
herm coco-stop        # 停止
herm coco-ask <问题>   # 发送编码任务
herm coco-log [行数]   # 查看最近输出
herm coco-attach      # 进入交互终端
```

模型: `deepseek-v4-pro`（编码需高质量）
tmux session 名: `coco-agent`

### 全局

```bash
herm stop             # 停止所有 agent
herm help             # 显示帮助
```

---

## hermes — 引擎命令

```bash
hermes status         # 引擎诊断（模型/API/网关/定时任务）
hermes doctor         # 详细诊断
hermes setup          # 配置向导
hermes update         # 更新 Hermes
hermes config         # 配置管理
hermes profile list   # 列出所有 profile
hermes sessions       # 查看会话
hermes cron list      # 查看定时任务
```

---

## agent-status — 详细状态

```bash
agent-status          # 显示 agent session + 状态文件 + 活跃 .task
```

输出示例:
```
◆ Agent Sessions
  🟢 wiki-agent      running
  🔴 qa-agent        DOWN

◆ Last Status Files
  qa-agent        2026-05-02T07:35  Pilot对比完成

◆ Active Tasks
  📋 hermes-team-3   [assigned]     qa-agent     QA Agent 完整 SOUL 定义
```

---

## tmux 直接操作（高级）

```bash
tmux list-sessions                    # 列出所有 session
tmux attach -t hermes-wiki            # 进入 wiki-agent
tmux attach -t qa-agent               # 进入 qa-agent
tmux attach -t coco-agent             # 进入 coco-agent
tmux kill-session -t hermes-wiki      # 强制停止 wiki-agent
tmux capture-pane -t qa-agent -p -S -50  # 捕获 qa-agent 最近 50 行
```

---

## 常用工作流

### 启动全部 agent

```bash
herm wiki-start && herm qa-start && herm coco-start
```

### 给 agent 发任务

```bash
# 单条消息（⚠️ 不要拆成多条，会互相打断）
herm qa-ask "审查 TASK_SPEC.md 的字段设计，重点关注必填/可选区分"

# 通过 /tmp 文件批量注入上下文
cat > /tmp/qa-context.txt << 'EOF'
任务文件: ~/.hermes/projects/autosar-1.task
审查维度: 状态机完整性、边界条件、验收标准可测性
EOF
herm qa-ask "读 /tmp/qa-context.txt，按三维度审查并写 /tmp/hermes-qa.status"
```

### 验收 agent 完成

```bash
# 1. 查看通知文件
cat /tmp/hermes-qa-*.status

# 2. 查看 agent 输出
herm qa-log 50

# 3. 进交互终端细看
herm qa-attach
```

### 日常检查

```bash
herm status && agent-status
```

---

## 文件路径速查

| 用途 | 路径 |
|------|------|
| herm 脚本 | `~/bin/herm` |
| agent-status 脚本 | `~/.hermes/scripts/agent_status.py` |
| wiki-agent profile | `~/.hermes/profiles/wiki-agent/` |
| qa-agent profile | `~/.hermes/profiles/qa-agent/` |
| coco-agent profile | `~/.hermes/profiles/coco-agent/` |
| .task 运行时 | `~/.hermes/projects/*.task` |
| agent 通知文件 | `/tmp/hermes-*.status` |
| shared-skills | `~/.hermes/shared-skills/` |
| wiki-agent 知识库 | `/mnt/f/04_Obsidian/` |

---

## 模型分配

| Agent | 模型 | 原因 |
|-------|------|------|
| 小艾 (PM) | deepseek-v4-pro | 决策/分配/验收需高质量 |
| QA agent | deepseek-v4-flash | 审查以量为主，快速迭代 |
| wiki-agent | deepseek-v4-flash | 知识搬运/转换，机械操作 |
| coco-agent | deepseek-v4-pro | 编码需精确，一次写对 |

---

## 注意事项

- ⚠️ tmux send-keys 连续发多条消息会互相打断 → 一条消息包含全部上下文
- ⚠️ agent 完成后写 `/tmp/hermes-{name}-{task_id}.status` 通知小艾
- ⚠️ agent 的 state.db 必须用 `hermes profile create --clone-from default` 后替换，防身份混淆
- ⚠️ 新建 agent 前必加载 `persistent-subagent` skill
- ⚠️ `vim`/`nano` 等交互编辑器在 tmux 里可用，`Ctrl+B D` detach 后不会中断
