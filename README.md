# Hermes Team

> Agent 团队管理 — 角色定义、工作空间、skill 配置、通信协议。
> **角色单源**: [docs/registry.md](docs/registry.md)

## 团队架构

```
小艾 (战略架构师)
  └── PM-agent (技术架构师+调度者)
        ├── QA Agent (质量守门人)
        ├── coco-agent (编码)
        └── wiki-agent (知识库+信息资产)
```

## 当前 Agent 清单

| Agent | 模型 | Profile | 触发方式 |
|-------|------|---------|---------|
| 小艾 | v4-pro | ~/.hermes/ | CLI/微信 |
| PM-agent | v4-pro | ~/.hermes/profiles/pm-agent/ | tmux |
| QA Agent | v4-flash | ~/.hermes/profiles/qa-agent/ | tmux |
| coco-agent | v4-flash | ~/.hermes/profiles/coco-agent/ | tmux |
| wiki-agent | v4-flash | ~/.hermes/profiles/wiki-agent/ | tmux |

> 完整角色定义见 [registry.md](docs/registry.md)，运行状态用 `herm status` 查看。

## 关联

- **Skill 管控**: [skills/](./skills/)（中心清单 + 索引 + 部署脚本）
- 治理规则: [hermes-governance](https://github.com/duanhaoyu88/hermes-governance)
- 项目管控: [hermes-project-control](https://github.com/duanhaoyu88/hermes-project-control)
- 知识库: `/mnt/f/04_Obsidian/`
