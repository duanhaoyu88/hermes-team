# Hermes 团队注册表

> 最后更新: 2026-05-02

## 团队架构

```
小宇哥
  └── 小艾 (架构师) — 方案设计、架构决策
        │
        └── PM-agent (调度) — 任务分配、执行闭环
              ├── QA Agent (审查) ←→ Coco (编码) — 审查修复直连循环
              └── wiki-agent (知识库) — 被动查询 + 主动维护 + 决策归档
```

## Agent 角色卡片

### 小艾
- **角色**: 架构师
- **职责**: 方案设计、架构决策、与用户沟通、向 PM-agent 派发宏观任务
- **Profile**: ~/.hermes/
- **Session**: xiao-ai
- **触发**: CLI / 微信
- **能力**: [architecture, planning, decision-making]

### PM-agent
- **角色**: 执行调度者
- **职责**: 接收小艾任务 → 分配 QA/Coco/Wiki → 协调闭环 → 汇报结果
- **Profile**: ~/.hermes/profiles/pm-agent/
- **Session**: pm-agent
- **触发**: tmux send-keys -t pm-agent（小艾派发）/ tmux send-keys（agent 汇报）
- **模型**: deepseek-v4-flash
- **自主权**: 代码类任务自主闭环。架构变更/新 agent/数据方向 → 必须汇报小艾
- **能力**: [task-delegation, progress-tracking, qa-coco-coordination, wiki-query]

### QA Agent
- **角色**: 质量守门人
- **职责**: 审查验收（不执行），审完直接通知 Coco 修复
- **Profile**: ~/.hermes/profiles/qa-agent/
- **Session**: qa-agent
- **触发**: tmux send-keys -t qa-agent（PM-agent 派发）
- **模型**: deepseek-v4-flash
- **能力**: [code-review, architecture-review, specification-review, communication-analysis]

### coco-agent
- **角色**: 编码实现
- **职责**: 写代码、修 bug、跑测试、交 PR。收到 QA 审查意见后自行修复
- **Profile**: ~/.hermes/profiles/coco-agent/
- **Session**: coco-agent
- **触发**: tmux send-keys -t coco-agent（PM-agent 或 QA 派发）
- **模型**: deepseek-v4-pro
- **能力**: [code-implementation, bug-fixing, testing, pr-creation, code-review]

### wiki-agent
- **角色**: 知识库
- **职责**: L1 被动查询 / L2 主动维护（Cron 6h 扫断链）/ L3 决策归档
- **Profile**: ~/.hermes/profiles/wiki-agent/
- **Session**: wiki-agent
- **触发**: tmux send-keys -t wiki-agent（任何人可查）
- **模型**: deepseek-v4-flash
- **能力**: [pdf-conversion, document-organization, markdown-editing, knowledge-base-compilation, link-checking]

## 通信协议矩阵

| 从 → 到 | 小艾 | PM-agent | QA | Coco | Wiki | 用户 |
|---------|------|----------|-----|------|------|------|
| 小艾 | - | send-keys | - | - | - | 微信/CLI |
| PM-agent | send-keys | - | send-keys | send-keys | send-keys | - |
| QA | - | send-keys | - | send-keys | send-keys | - |
| Coco | - | send-keys | send-keys | - | send-keys | - |
| Wiki | - | send-keys | send-keys | send-keys | - | - |

## Agent 加入流程

1. `hermes profile create <name> --clone-from default`
2. 替换 state.db，清空 MEMORY
3. 编写 SOUL.md + AGENTS.md（含通信协议 + Capabilities）
4. 添加到 ~/bin/herm
5. 注册到本注册表 + 创建角色页 docs/agents/<name>.md
6. 更新 commands.md
7. 通信测试：send-keys → agent 写 status → watcher 检测
