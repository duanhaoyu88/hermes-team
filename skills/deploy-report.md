# Deploy Report — Skill 部署清单

> 生成时间: 2026-05-03T06:37:25Z
> 源文件: /mnt/f/03_Github/hermes-team/skills/scripts/../skill-map.yaml
> 总计: 17 个 skill

## 部署概览

| 角色 | auto | manual | never | 小计 |
|------|------|--------|-------|------|
| coco | 2 | 9 | 0 | 11 |
| pm | 2 | 4 | 0 | 6 |
| qa | 2 | 2 | 0 | 4 |
| wiki | 4 | 0 | 0 | 4 |

## 详细分配

### coco

**auto（启动加载）:**
  - `hermes-agent-comms` — 启动时自动加载
  - `test-driven-development` — 编码前自动加载

**manual（按需加载）:**
  - `systematic-debugging` — 遇到 bug 或异常行为时加载
  - `requesting-code-review` — 提交代码审查前自查
  - `github-pr-workflow` — 提交 PR 时加载
  - `github-code-review` — 自查 diff 时加载
  - `github-issues` — 操作 Issue 时加载
  - `github-repo-management` — 进新项目时加载
  - `codebase-inspection` — 首次进项目时加载
  - `bypass-profile-path-resolution` — 首次配置环境时按需加载
  - `github-auth` — 首次配置 git 认证时按需加载

**never（禁止加载）:**

### pm

**auto（启动加载）:**
  - `hermes-agent-comms` — 启动时自动加载
  - `plan` — 启动时自动加载

**manual（按需加载）:**
  - `design-doc-review` — 收到设计文档审查任务时加载
  - `github-issues` — 操作 Issue 时加载
  - `github-repo-management` — 进新项目时加载
  - `codebase-inspection` — 首次进项目时加载

**never（禁止加载）:**

### qa

**auto（启动加载）:**
  - `hermes-agent-comms` — 启动时自动加载
  - `qa-acceptance-review` — 审查任务时自动加载

**manual（按需加载）:**
  - `design-doc-review` — 收到设计文档审查任务时加载
  - `systematic-debugging` — 遇到 bug 或异常行为时加载

**never（禁止加载）:**

### wiki

**auto（启动加载）:**
  - `hermes-agent-comms` — 启动时自动加载
  - `llm-wiki` — 启动时自动加载
  - `wechat-dual-agent-routing` — 启动时自动加载
  - `obsidian` — 操作 Obsidian 时加载

**manual（按需加载）:**

**never（禁止加载）:**

## 交叉检查

- name 唯一性: ✅ 通过
- 角色引用: 每个 skill 被至少一个角色的 auto 或 manual 引用
- load 值: 全部在 [auto, manual, never] 范围内
