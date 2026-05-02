# Hermes 团队注册表

> 最后更新: 2026-05-02

## 团队架构

```
小艾 (PM/架构师)
  ├── QA Agent (质量守门人) ← 骨架已建，完整定义由 QA 自己接手
  ├── wiki-agent (知识库)
  ├── coco-agent (编码)
  └── delegate_task (一次性独立审查，非持久 agent)
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
- **Skill**: 按任务加载 (code-review, test-runner 等)
- **触发**: tmux send-keys（project-control 任务消息）
- **能力**: [code-implementation, code-review, testing]

### QA Agent
- **角色**: 质量守门人
- **职责**: 审查验收（不执行）
- **Profile**: ~/.hermes/profiles/qa-agent/
- **AGENTS**: AGENTS.md（骨架已建，完整定义待 QA 自己接手）
- **Skill**: 待定义（预留 qa-checklist, qa-standards）
- **触发**: 扫描 .task 文件找 needs_review 任务 + tmux send-keys 接收打回通知
- **能力**: [review, verification, quality-gate]

### delegate_task
- **角色**: 一次性独立审查
- **职责**: 无上下文污染的规范/架构审查
- **Profile**: 无持久 Profile（每次新建实例）
- **触发**: 小艾通过 delegate_task 工具调用
- **能力**: [independent-review, fresh-eyes]

## 通信协议矩阵

| 从 → 到 | 小艾 | wiki-agent | coco-agent | QA Agent | 用户 |
|---------|------|-----------|-----------|---------|------|
| 小艾 | - | tmux send-keys | tmux send-keys / delegate_task | tmux send-keys | 微信/CLI |
| wiki-agent | Issue Comment | - | 不直接通信 | 不直接通信 | 不直接通信 |
| coco-agent | Issue Comment | 不直接通信 | - | 不直接通信 | 不直接通信 |
| QA Agent | Issue Comment | 不直接通信 | 不直接通信 | - | 不直接通信 |
| 用户 | 微信 | 不直接通信 | 不直接通信 | 不直接通信 | - |

## 消息格式

与 TASK_SPEC v1.2 完全一致：

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

| 场景 | 检测方式 | 处理 |
|------|---------|------|
| Agent 离线 | assigned 超时 | 巡检退回 pending |
| 消息丢失 | assigned 超时 | 退回 pending，重新分配 |
| Agent 崩溃/hang | running 超时 (running_timeout_minutes) | 巡检退回 pending |
| Agent 报错 | agent 写 status=failed | Issue Comment 告警，等待小艾处理 |
| 任务取消 | 小艾发 task_cancel | tmux C-c 中断 + status=cancelled |
| 依赖死锁 | DFS 环检测 | 分配前拒绝，不分配 |
| 并发写入 | 原子写入 (temp+rename) | 读方始终看到完整文件 |
| .task 损坏 | hash 校验失败 | 从 Issue 重建 |
| GitHub 不可用 | 网络检测 | .task 离线自洽，恢复后批量同步 |

## Agent 加入流程

1. 创建 Profile 目录 + 最小 AGENTS.md
2. 注册到本注册表
3. 配置通信通道（tmux/delegate_task）
4. 运行冒烟测试（`smoke_test.py`）
5. 完成角色定义（由 agent 自己接手）
