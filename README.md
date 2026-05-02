# Hermes Team

> Agent 团队管理 — 角色定义、工作空间、skill 配置、通信协议。
>
> 📄 知识库: `/mnt/f/04_Obsidian/ai-agent/projects/hermes-team.md`

## 团队架构

```
小艾 (架构师)
  └── PM-agent (执行调度者)
        ├── QA Agent (质量守门人)
        ├── coco-agent (编码)
        └── wiki-agent (知识库)
```

## 当前 Agent 清单

| Agent | 配置 | Profile | 触发方式 |
|-------|------|---------|---------|
| 小艾 | ✅ | ~/.hermes/ | CLI/微信 |
| PM-agent | ✅ | ~/.hermes/profiles/pm-agent/ | tmux (小艾派发) |
| QA Agent | ✅ | ~/.hermes/profiles/qa-agent/ | tmux (PM-agent派发) |
| coco-agent | ✅ | ~/.hermes/profiles/coco-agent/ | tmux (PM-agent派发) |
| wiki-agent | ✅ | ~/.hermes/profiles/wiki-agent/ | tmux (PM-agent派发) |

> 运行状态用 `herm status` 查看。

## 目录结构

```
docs/
├── agents/
│   ├── xiao-ai.md       ← 小艾：角色、SOUL、skill、工作空间
│   ├── pm-agent.md      ← PM-agent：调度、闭环、进度追踪
│   ├── wiki-agent.md    ← wiki-agent：角色、skill、工作空间
│   ├── coco-agent.md    ← coco-agent：角色、skill、工作空间
│   └── qa-agent.md      ← QA agent：审查、方案评估
├── protocols/
│   ├── communication.md ← 通信协议矩阵
│   └── onboarding.md    ← 新 agent 加入流程
└── registry.md          ← 团队注册表
```

## 关联

- 项目管控: [hermes-project-control](https://github.com/duanhaoyu88/hermes-project-control)
- 治理体系: [hermes-skill-governance](https://github.com/duanhaoyu88/hermes-skill-governance)
- 知识库: `/mnt/f/04_Obsidian/`
