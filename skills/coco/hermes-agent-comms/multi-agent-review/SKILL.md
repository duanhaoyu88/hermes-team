---
name: multi-agent-review
description: Cross-agent review protocol — PM collects independent opinions from QA/Coco/Wiki, iterates until consensus
when_to_use: When user wants all agents to review a proposal/design/schema and wants genuine independent thinking (not rubber-stamping)
---

# Multi-Agent Review Protocol

## Pattern

```
小艾 → PM: "让QA/Coco/Wiki审X，每人独立给意见，汇总后回报"
         │
    PM → QA: "从你的角色角度审X"
    PM → Coco: "从你的角色角度审X"
    PM → Wiki: "从你的角色角度审X"
         │
    收集三人意见 → 汇报小艾
         │
    小艾审 → 满意？→ 批准
           → 不满意 → 打回，要求每人至少一条反对意见
```

## Key Rules

1. **Must require independent thinking** — explicitly tell PM "每人必须提出反对意见或质疑"
2. **Check for rubber-stamping** — if all three return "✅ 同意" with zero challenges, reject it
3. **Iterate until real debate happens** — first round is often passive agreement, second round with specific challenges brings real discussion
4. **Specify what to challenge** — give concrete gaps to address, don't just say "think independently"
5. **When review misses bugs** — after fixing, demand a retro doc analyzing root causes + prevention measures. Template: `governance/retro-{topic}.md` with 5 why's format

## Example

```
Good: "QA/Coco/Wiki每人必须提出至少一条反对意见或质疑。具体缺口：1.上限7条依据在哪 2.P0只扫README够不够"
Bad:  "让他们讨论一下"
```

## Integration

- PM uses `herm *-ask` with `[pm-agent]` prefix for each agent
- PM collects via `tmux capture-pane`
- Results documented in Issue comments or retro docs
