---
name: karpathy-guidelines
category: software-development
description: Behavioral coding guidelines derived from Andrej Karpathy's observations on LLM coding pitfalls — think before coding, simplicity first, surgical changes, goal-driven execution.
when_to_use: 编码前参考行为准则或遇到 LLM 编码反模式时加载。
---

**Core principle: 先思考再编码、简洁优先、外科手术式修改、目标驱动。**

# Karpathy Guidelines for Hermes

Behavioral guidelines to reduce common LLM coding mistakes.
Derived from Andrej Karpathy's observations:
> "The models make wrong assumptions, overcomplicate code, change things they don't understand, and don't manage their confusion."

**Complements:** `harness-creator` (harness = structure, karpathy = behavior)
**Trigger:** Any coding task, regardless of size.

---

## Four Principles

### 1. Think Before Coding
**Don't assume. Don't hide confusion. Surface tradeoffs.**

- State assumptions explicitly. If uncertain, **ask before implementing**.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, **stop**. Name what's confusing. Ask.

### 2. Simplicity First
**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If 200 lines could be 50, rewrite it.

*Test: Would a senior engineer say this is overcomplicated? If yes, simplify.*

### 3. Surgical Changes
**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, **mention it** — don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

*Test: Every changed line should trace directly to the user's request.*

### 4. Goal-Driven Execution
**Define success criteria. Loop until verified.**

| Instead of... | Transform to... |
|--------------|-----------------|
| "Add validation" | "Write tests for invalid inputs, then make them pass" |
| "Fix the bug" | "Write a test that reproduces it, then make it pass" |
| "Refactor X" | "Ensure tests pass before and after" |

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let the LLM loop independently. Weak criteria ("make it work") require constant clarification.

---

## When These Guidelines Are Working
- Fewer unnecessary changes in diffs
- Fewer rewrites due to overcomplication
- Clarifying questions come **before** implementation, not after mistakes