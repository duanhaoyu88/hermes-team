---
name: qa-acceptance-review
description: >
  QA Agent's structured review methodology — verify a task output against its
  .task file acceptance criteria, check for breaking changes in external callers,
  and produce a structured JSON report. Used after an agent reports needs_review.
version: 1.2.0
author: QA Agent (Hermes)
tags: [qa, review, acceptance, breaking-change, hermes]
---

# QA Acceptance-Criterion-Driven Review

Systematic verification of a task output against its `.task` file acceptance criteria.

**Core principle:** You are an independent reviewer. The implementer has blind spots — your job is to find what they missed by taking a fresh, evidence-driven approach.

## When to Use

- When an agent sets `.task` status to `needs_review`
- When asked to "review" a specific file or function
- When a change touches functions/APIs that other modules depend on

## Step 0 — Classify the change type

Before gathering details, determine the **change type** from the Issue body or agent's status report. This sets your review depth and scope:

| Type | Scope | Review depth |
|------|-------|-------------|
| `docs` | Documentation only | Cross-references, format consistency, dead links |
| `fix` | Bug fix | Fix completeness, no regression, side effects |
| `feat` | New feature | Feature completeness, edge cases, backward compat |
| `schema` | Data structure change | **P0 cascade audit** — must check all consumer files (see Step 5b P0 pattern) |

If no type is specified, infer from the nature of the change and document your assumption in the report.

## Step 1 — Gather context

Read three sources before anything else:

```python
# 1. The review specification or user's request
# 2. The .task file (for acceptance criteria)
# 3. The agent's completion status file (/tmp/hermes-{agent}-{task_id}.status)
```

The user's request or the Issue body tells you **what** to review and **which acceptance criteria** apply. The `.task` file tells you the full spec. The agent's status file tells you what they claim to have done.

## Step 2 — Read the actual source files

Never trust a summary. Read the actual modified files:

```python
# Use read_file or terminal(cat) to get the full file content
# If a git repo exists, check the diff:
git diff HEAD -- <file>
```

This shows you exactly what changed, not what the agent said changed.

## Step 3 — Verify each acceptance criterion

Create an evidence table with **evidence_type** classification. For each criterion, mark whether the evidence is:

- **reproducible** — objective, command-based, verifiable by re-running. Evidence field must contain the exact command + output result. Example: `search_files('*.md') → 12 files; bash run-tests.sh → exit 0`
- **judgment** — subjective, scope-based, requires domain knowledge. Evidence must contain: scope examined + observations + basis for judgment. Example: `Scanned 12 .py files in src/. All def statements use snake_case. Sampled 3 files with no exceptions. Consistent with style guide.`

Then ask:

1. Does the code do what the criterion says?
2. Is there **proof** in the code (not just the commit message)?
3. Are edge cases handled? (empty input, missing fields, corrupted data, permissions)
4. **For scripts/CLI tools: run it.** Code reading tells you what it *should* do; running tells you what it *actually* does. Runtime catches: PATH issues, missing permissions, dependency versions, exit code behavior, output format quirks.

```python
acceptance_results = {
    "AC1_something": {
        "pass": True/False,
        "evidence": "specific line of code + why it satisfies or fails"
    },
    ...
}
```

Be specific. "JSON parsing works" is bad evidence. "json.load(f) parses the file, data.get('ttl_seconds', DEFAULT) handles missing fields" is good evidence.

**Runtime verification pattern (scripts/tools only):**
```bash
# Run the script once to verify exit code + output format
bash path/to/script.sh arg1 arg2
echo "exit=$?"  # Must match expected: 0 for success, non-zero for rejection

# For tests: run both positive and negative cases
bash path/to/test.sh            # All tests, check exit 0
bash path/to/script.sh bad.json # Error case, check exit ≠ 0

# Capture output and verify format (human-readable, structured, etc.)
bash path/to/script.sh > /tmp/output.log 2>&1
grep -q "✅" /tmp/output.log || echo "missing PASS marker"
```
If the script fails at runtime, first rule out environment issues (missing PATH entry, uninstalled dependency) before concluding the code is wrong.

## Step 4 — Search for breaking changes (KEY INSIGHT)

This is the most commonly missed check. When a function's **signature, return type, or behavior** changes, every caller breaks silently.

```python
# Search the entire project for the function/class name:
import re, subprocess
result = subprocess.run(
    ["grep", "-rn", "function_name", "/project/path", "--include=*.py"],
    capture_output=True, text=True
)
```

If you find callers, **read those files** to confirm they still work with the new signature.

**Ask specifically:**
- Does the return type match what callers expect? (list → dict is a breaking change)
- Did any parameter names change? (keyword args break)
- Did a required parameter become optional, or vice versa?
- Did the function raise new exceptions that callers don't handle?

## Step 5 — Cross-reference with test files

Find and read the test files:

```python
grep -rn "import.*patrol\|from.*patrol import\|patrol()" --include="*.py" /project
```

Test files often use the function directly and are the first to break. If a test exists and would crash, that's a **critical finding**.

## Step 5b — Cross-file consistency audit (multi-file reviews only)

When a commit touches multiple files, the implementer's blind spot is **cross-file inconsistency** — changing one file without propagating to its dependents. The implementer sees each file in isolation; you see the whole picture.

**Always check these:**

1. **Entry-point files** — README.md, index docs. These are the repo's front door and are systematically overlooked. Check that README tables (status, phase, version) match the authoritative document.

2. **Schema-to-documentation propagation** — When a schema field changes (e.g., `docs_updated` removed, `evidence_type` added), search the entire repo for all files that reference the old field name. Schema definition → examples → permission matrix → flow rules → templates → scripts. One change can ripple through 6+ files.

3. **Phase/status tables across documents** — If DESIGN.md and README.md both have a Phase table, verify every cell agrees. A ✅ in one place and ⬜ in another for the same entity is a red flag.

4. **Enum consistency** — If labels.md defines label names, verify that workflow status tables, permission matrices, and flow rules all use the exact same enum values (e.g., `qa-passed` vs `qa_passed` vs `qa_pass`).

**Execution pattern:**
```bash
# After reading the diff and understanding what changed:
# 1. Identify the "source of truth" document for each changed concept
# 2. List all other files that reference the same concept
# 3. For each pair, cross-reference cell by cell

# Example: after finding a Phase status table change in DESIGN.md:
grep -n "Phase [0-9]" README.md DESIGN.md harness-schema.md
# Compare every occurrence — they must agree on description and status
```

**Common patterns to catch:**
- README.md Phase table stale after DESIGN.md update (found in practice: DESIGN said ✅"已就位" but README said ⬜"待启动" in the same commit)
- Field removed from schema definition but still present in example JSON
- New enum value defined in one file but not in the approval matrix or flow rules

#### P0 cascade pattern (schema changes only)

When `change_type = schema`, the review scope expands to a mandatory **5-level cascade**:

```
schema definition → documentation → templates → scripts → consumers
```

| Level | File | What to check |
|-------|------|--------------|
| **定义** | Schema definition (e.g., harness-schema-qa.json) | Field name, type, enum values, required array |
| **文档** | Architecture/doc files referencing the schema | Field descriptions, examples match definition |
| **模板** | All templates referencing schema fields | Field names match schema (grep for old names) |
| **脚本** | Validation/conversion/generation scripts | Logic uses new field name, not the old one |
| **消费方** | Entire repo — search for old field name | No stale references to removed/renamed fields |

**Execution pattern:**
```bash
# 1. Identify changed field names from the diff
# 2. For each old name, grep the entire repo:
grep -rn "old_field_name" /repo/path --include="*.json" --include="*.yaml" --include="*.md" --include="*.sh"
# 3. Each match must be either:
#    - Already updated to new name (✅)
#    - In a file not yet updated (❌ — list in findings)
```

Cross-repo changes (schema in governance repo, consumers in project repo): note the gap but limit your audit scope to what the Issue covers. Flag the cross-repo gap in the report.

## Step 6 — Write the structured JSON status file

Write to `/tmp/hermes-qa-{task_id}.status` with this schema:

```json
{
  "agent": "qa",
  "task_id": "{task_id}",
  "status": "needs_review",
  "time": "ISO8601 timestamp",
  "summary": "✅ 通过 / ❌ 不通过 / ⚠️ 条件通过 — brief verdict",

  "acceptance_results": {
    "AC1_name": {"pass": true/false, "evidence": "..."},
    "AC2_name": {"pass": true/false, "evidence": "..."}
  },

  "findings": [
    {
      "severity": "critical|minor|info",
      "file": "path/to/file.py",
      "line": 42,
      "issue": "brief description",
      "detail": "detailed explanation",
      "fix": "suggested fix (optional)"
    }
  ],
}
```

Severity levels:
- **critical**: Breaks existing functionality (test failures, silent data loss, crash)
- **minor**: Works but has format/style/edge-case issues that should be fixed
- **info**: Debts, recommendations, low-risk observations

### Verdict rules

| Verdict | Condition | Action |
|---------|-----------|--------|
| ✅ 通过 | All acceptance criteria pass, no unexpected findings | Report + notify PM |
| ⚠️ 条件通过 | All criteria pass BUT minor issues exist (fix < 5 min each, no downstream block) | Report + list fixes + notify PM. PM decides whether to accept or reset to running |
| ❌ 不通过 | Any core criterion fails, or critical finding blocks usability | Report + list all failures with evidence. PM must reset to running |

**Conditional pass examples (合法):** formatting typo, one dead link, missing --help text, ambiguous comment that needs clarification
**Not conditional pass (必须 ❌):** core feature missing, script crashes on normal input, acceptance criterion unmet, fixture files modified when they shouldn't be

## Step 7 — Communicate findings to the implementer (optional)

If the implementer's tmux session is running, send findings directly:

```bash
tmux send-keys -t {agent-session} "QA Review: {task} — {key findings}" Enter
```

Keep it concise — they don't need the full JSON, just the actionable items. Include the path to the full report: `cat /tmp/hermes-qa-{task_id}.status`

## Pitfalls

- **Not checking external callers** — The implementer only changed one function. They don't know who imports it. You need to find that out.
- **Trusting the agent's self-verification** — Coco's status file said `"stderr_format_ok": true` but the format was wrong. Always verify independently.
- **Acceptance ≠ implementation** — The code might satisfy the letter of the criterion but miss the spirit (e.g., stderr log exists but format is wrong).
- **Skipping cross-file consistency** — When a commit touches multiple files, the implementer's biggest blind spot is forgetting to propagate changes from one file to its dependents. README is the most commonly missed file.
- **JSON status file errors** — Use `write_file` not `echo`, to avoid JSON formatting issues.
- **Silent error handling** — Bare `except: pass` hides problems. Flag it when you see it.
