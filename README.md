# Hermes Team

> Agent 团队管理 — 角色定义、工作空间、skill 配置、通信协议。
>
> 📄 知识库: `/mnt/f/04_Obsidian/ai-agent/projects/hermes-team.md`

## 团队架构

```
小艾 (PM/架构师)
  ├── QA Agent (质量守门人) ← 待搭建
  ├── wiki-agent (知识库)
  ├── coco-agent (编码)
  └── delegate_task (一次性审查/编码)
```

## 当前 Agent 清单

| Agent | 状态 | Profile | 触发方式 |
|-------|------|---------|---------|
| 小艾 | ✅ 运行中 | ~/.hermes/ | CLI/微信 |
| wiki-agent | ✅ 运行中 | ~/.hermes/profiles/wiki-agent/ | tmux |
| coco-agent | ✅ 运行中 | ~/.hermes/profiles/coco-agent/ | delegate_task |
| QA Agent | ⏳ 待搭建 | ~/.hermes/profiles/qa-agent/ | tmux/delegate_task |

## 目录结构

```
docs/
├── agents/
│   ├── xiao-ai.md       ← 小艾：角色、SOUL、skill、工作空间
│   ├── wiki-agent.md    ← wiki-agent：角色、skill、工作空间
│   ├── coco-agent.md    ← coco-agent：角色、skill、工作空间
│   └── qa-agent.md      ← QA agent：角色定义（待设计）
├── protocols/
│   ├── communication.md ← 通信协议矩阵
│   └── onboarding.md    ← 新 agent 加入流程
└── registry.md          ← 团队注册表
```

## 关联

- 项目管控: [hermes-project-control](https://github.com/duanhaoyu88/hermes-project-control)
- 治理体系: [hermes-skill-governance](https://github.com/duanhaoyu88/hermes-skill-governance)
- 知识库: `/mnt/f/04_Obsidian/`
