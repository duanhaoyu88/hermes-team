# Hermes 团队注册表

> 最后更新: 2026-05-02

## 团队架构

```
小艾 (PM/架构师)
  ├── QA Agent (质量守门人) ← 骨架已建，完整定义由 QA 自己接手
  ├── wiki-agent (知识库)
  └── coco-agent (编码)
```

## Agent 角色卡片

### 小艾
- **角色**: PM / 架构师
- **职责**: 需求分析、任务分解、调度分配、验收
- **Profile**: ~/.hermes/
- **SOUL**: ~/.hermes/SOUL.md
- **Skill**: project-control (7 操作)
- **触发**: CLI / 微信
- **能力**: [planning, architecture, review, coordination]

### wiki-agent
- **角色**: 知识库管理
- **职责**: PDF 转换、概念页编写、知识库维护
- **Profile**: ~/.hermes/profiles/wiki-agent/
- **AGENTS**: AGENTS.md（含 project-control 协议）
- **Skill**: llm-wiki, mineru-ai, obsidian-wiki-ops
- **触发**: tmux send-keys（project-control 任务消息）
- **能力**: [knowledge-base, pdf-conversion, document-organization]

### coco-agent
- **角色**: 编码实现
- **职责**: 代码编写、测试、PR
- **Profile**: ~/.hermes/profiles/coco-agent/
- **AGENTS**: AGENTS.md（含 project-control 协议）
- **Skill**: 按任务加载
- **触发**: delegate_task（project-control 任务消息）
- **能力**: [code-implementation, code-review, testing]

### QA Agent
- **角色**: 质量守门人
- **职责**: 审查验收（不执行）
- **Profile**: ~/.hermes/profiles/qa-agent/
- **AGENTS**: AGENTS.md（骨架已建，完整定义待 QA 自己接手）
- **触发**: 扫描 .task 文件找 needs_review 任务
- **能力**: [review, verification, quality-gate]

## 通信协议矩阵

| 从 → 到 | 小艾 | wiki-agent | coco-agent | QA Agent | 用户 |
|---------|------|-----------|-----------|---------|------|
| 小艾 | - | tmux send-keys | delegate_task | delegate_task | 微信/CLI |
| wiki-agent | Issue Comment | - | 不直接通信 | 不直接通信 | 不直接通信 |
| coco-agent | Issue Comment | 不直接通信 | - | 不直接通信 | 不直接通信 |
| QA Agent | Issue Comment | 不直接通信 | 不直接通信 | - | 不直接通信 |
| 用户 | 微信 | 不直接通信 | 不直接通信 | 不直接通信 | - |

## 消息格式

### 任务分配 (小艾 → agent)
```json
{"type":"task_assign","project":"AUTOSAR","task_id":3,"title":"minerU 批量转换","task_file":"~/.hermes/projects/autosar-compile-3.task","issue_url":"https://github.com/..."}
```

### 打回通知 (小艾 → agent)
```json
{"type":"task_reject","task_id":3,"failed_items":[3,4],"note":"输出缺少交叉引用"}
```

### 取消通知 (小艾 → agent)
```json
{"type":"task_cancel","task_id":3}
```

### Agent 汇报 (agent → 小艾)
写 GitHub Issue Comment，格式：
```markdown
## [时间戳] agent-name: 任务完成
- 完成内容: ...
- 产出路径: ...
- 备注: ...
```

## 错误处理

- Agent 离线 → 小艾巡检检测超时 → 退回 pending
- 消息丢失 → assigned 超时自动退回 → 重新分配
- Agent 报错 → 写 .task status=failed + Issue Comment

## Agent 加入流程

1. 创建 Profile 目录 + 最小 AGENTS.md
2. 注册到本注册表
3. 配置通信通道（tmux/delegate_task）
4. 运行冒烟测试
5. 完成角色定义（由 agent 自己接手）
