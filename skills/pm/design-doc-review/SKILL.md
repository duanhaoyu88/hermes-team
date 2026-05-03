---
name: design-doc-review
description: >
  Review design documents (architecture, state machines, label systems,
  templates) for internal consistency, stakeholder coverage, edge case
  handling, and completeness. Used before implementation begins.
version: 1.0.0
author: QA Agent (Hermes)
tags: [qa, review, design, governance, consistency]
---

# Design Document Review Methodology

Systematic review of design documents before implementation. Different from task output review — you're reviewing plans, not products.

**Core principle:** Design docs have three failure modes that code doesn't — internal contradiction, stakeholder blind spots, and unhandled edge cases in the design itself. Your job is to catch these before anyone starts coding.

## When to Use

- When asked to review an architecture doc, DESIGN.md, or specification
- When a multi-file deliverable has design decisions across documents (DESIGN.md + labels.md + templates)
- When stakeholder requirements were collected and need to be verified against the design

## Review Dimensions

A design document review checks five dimensions:

| # | Dimension | What you're looking for |
|---|-----------|------------------------|
| 1 | Structure & logical flow | Does the document have a clear narrative? Are dependencies ordered correctly? |
| 2 | Internal consistency | Do different sections and companion documents agree? (e.g., state machine diagram vs label usage rules) |
| 3 | Stakeholder coverage | Are all known requirements from surveys/interviews actually reflected in the design? |
| 4 | Edge case handling | What happens on error paths? timeout? disagreement? overflow? |
| 5 | Feasibility | Is the migration path credible? Are dependencies listed? Are unclear phases flagged? |
| ⭐ 6 | Schema/field granularity | Does the proposed data structure (JSON fields, YAML config) have the granularity to support the real workflow? Missing evidence fields? Severity levels? Ownership metadata? |
| ⭐ 7 | Cross-role write conflicts | Which role writes which field? Can one role's edit silently overwrite another's data in a shared file? |
| ⭐ 8 | Notification/interaction protocol | How are role transitions triggered? send-keys? status file? Issue comment? Are there gaps where a role waits indefinitely? |

Dimensions ⭐6-8 are especially important when reviewing a **proposal (pre-write)** — a planned scheme before any document exists. They catch the issues that only surface when multiple roles interact through shared data structures.

## Step 1 — Read all deliverable files

Design docs often span multiple files. Read them all before forming opinions:

```python
# Read the main doc
read_file("governance/DESIGN.md")

# Read companion documents
read_file("governance/labels.md")

# Read each template
read_file("governance/templates/review-report.md")
```

Do NOT skim. Read each file line by line. The subtlest contradictions are line-level.

## Step 2 — Build a cross-document consistency map

After reading, map related claims across documents. This is the highest-value check.

Example pattern from practice:
- DESIGN.md §3.1 shows `blocked` as a **state machine node** (a step in the flow)
- labels.md §1 says `blocked` is **added on top of existing state** (not a step)
- → **Inconsistency found**: same concept, different semantics in two places

To find these:
1. Identify concepts that appear in multiple documents (state labels, state transitions, roles, responsibilities)
2. Compare their definitions side by side
3. Flag any contradiction

## Step 3 — Map stakeholder requirements to document content

If a survey or requirements gathering preceded the design, create a traceability table:

```
| Stakeholder | Requirement | In doc? | Location | Status |
|-------------|-------------|---------|----------|--------|
| QA          | conditional pass option | ✅ | §3.1 qa-conditional | aligned |
| QA          | standardized submission format | ❌ | — | MISSING |
```

This catches the most common design oversight: "they said they'd include it but didn't actually write it in."

## Step 4 — Check state machines and workflows for completeness

For any state machine, workflow, or lifecycle diagram, ask:

1. **Entry**: Where do items enter this flow? What preconditions?
2. **Forward paths**: Can every state reach a terminal state?
3. **Backward paths**: Can every state go back to a previous state? (Most designers forget these.)
4. **Error paths**: What happens when a review fails? a timeout occurs? a disagreement arises?
5. **Overflow/scale**: What happens when there are 100 items in the backlog? 0 review agents available?
6. **Orphan states**: Is there any state with no incoming edges? (Dead code in the state machine.)

### Step 5 — Check templates against real usage patterns

For document templates, check:

1. **Field completeness**: Does the template have every field a reviewer or implementer would need?
2. **Legacy contamination**: Does the template reference old systems that no longer exist?
3. **Hardcoded values**: Are agent names, paths, or versions hardcoded instead of using placeholders?
4. **Mutual coverage**: Do the templates together cover all workflow scenarios?
5. **Self-consistency**: Are the templates' own frontmatter labels correct?

### Step 5b — Schema/field granularity (pre-write proposal review)

When reviewing a **proposed data schema** (JSON fields, YAML config, shared status file) before it's written to any document:

1. **Workflow-granularity mapping**: For each field in the proposed schema, ask: "Which step in the real workflow uses this field?" If a step has no field (e.g., evidence for each acceptance criterion), the schema is too coarse.

2. **Derived vs stored fields**: Identify fields that should be computed (e.g., `review_count = len(review_history)`) rather than manually stored. Stored copies drift.

3. **Custom-specific field patterns**:
   - QA needs: `acceptance_results[{criterion, pass, evidence}]`, `findings[{severity, file, line, issue}]`, `conditional_items[{condition}]`
   - Some fields are summary-level (`qa_conclusion`), others are evidence-level per criterion — both levels are needed.

4. **Concrete schema suggestions**: When a field is missing, propose the exact JSON Schema (draft-07). Not "add more fields" — show the complete definition with `type`, `required`, `enum`, `const`, and `examples`. The proposer can't know what granularity you need; you must tell them.

   Patterns worth adopting in every schema proposal:
   - **Immutability anchors**: When a field references external content (e.g., acceptance criterion text from .task file), store a copy of the source text at review time (e.g., `criterion_text`). This prevents the external reference being changed later from invalidating the review evidence.
   - **`const` enforcement**: For role ownership fields (e.g., `checked_by`), use `"const": "qa"` in the schema. This enables automated validation to catch cross-role writes at the data layer, not just convention.
   - **Closure tracking for conditional states**: When a "conditional pass" state exists, design three fields for each conditional item: `resolved` (boolean), `resolved_at` (timestamp), `resolved_in_round` (int). This creates an auditable trail for incremental reviewers.

5. **Incremental context**: Does the schema support delta reviews? A flat `review_history` array does — every round appends. But ensure each round references the previous round's context so an incremental reviewer knows what changed. A `delta_from_round` field (int, nullable) marks which round the current review is responding to.

## Step 6 — Evaluate migration/phasing plan

A good design includes a credible migration path. Check:

1. **Ordering**: Are dependencies between phases correct? (Can't automate before you have labels.)
2. **Missing phases**: If stakeholder feedback requires infrastructure (e.g., "auto-notify QA"), is that phase explicitly planned?
3. **Phase gates**: Are there clear criteria for advancing to the next phase?
4. **Fallback**: What happens if a phase fails or takes too long?

## Step 6b — Cross-role write conflict analysis

When a shared data structure (JSON file, YAML, config) is written by multiple roles:

1. **Field ownership matrix**: Map each field to the role(s) that write it. If two roles write the same field, flag it.

2. **Overwrite scenario test**: Imagine role A updates the shared file to add `status=qa-passed`. Role B later updates the same file to set `current_task=X` — does role B's write preserve role A's fields? If using `json.dumps` full-write, the answer is NO.

3. **Solutions (in order of preference)**:
   - **Field prefix convention**: `qa_*` owned by QA, `coco_*` owned by Coco. Document the convention. Lightweight.
   - **Separate files per role**: `qa_report.json` + `coco_report.json` with cross-refs. Heavier but resilient.
   - **Write-lock via status**: Only the role with the current workflow token writes to the shared file.

4. **Derived field check**: If two roles can increment the same counter (e.g., `review_count`), derive it from array length instead of storing it.

### Step 6b.ii — Post-schema document consistency check (triple-pass)

When a JSON Schema (or data contract) already exists and you're reviewing a document that implements it, perform a **triple-pass consistency check** across three dimensions:

**Pass 1 — Schema-to-document field mapping**: Read the document's example data and walk every field against the schema definition. Use a table:

```
| Schema field | Required? | Schema type/enum | Doc example value | Status |
|--------------|-----------|------------------|-------------------|--------|
| conclusion   | yes       | enum: pass/fail/conditional | "fail" | ✅ |
| checked_by   | yes       | const: "qa"      | "qa"              | ✅ |
| severity     | yes       | enum: P0/P1/P2   | "P1"              | ✅ |
```

This catches: wrong enum values, missing required fields, type mismatches, and `const` violations.

**Pass 2 — Permission matrix cell-by-cell**: Walk the role-permission matrix (who writes what) one cell at a time. For each cell with ✅, verify:
- The role has write logic for that field defined elsewhere in the document
- The write is for the correct reason (e.g., QA writes status ONLY for review conclusions, not for scheduling)
- No field is claimed by two roles without the convention documented

**Pass 3 — Notification flow scenario-by-scenario**: For each transition in the workflow table, trace the full chain:
- Who triggers? → Channel → Who receives? → What do they do next?
- Verify no transition ends with "Notify: —" when a downstream role needs to act
- Verify channel reliability: Primary (real-time) + Secondary (persistent state) + Backup (GitHub/doc)

The triple-pass is overkill for a single-file design doc. Use it when the document has ≥3 interconnected sections (schema + matrix + workflow table) where inconsistencies between them are invisible when reading each section alone.

## Step 6c — Notification/interaction protocol audit

For every role transition in the workflow, verify a notification channel exists:

1. **Transition table**: List every state change and who triggers it, who needs to know, and the channel.

```
| From | To | Trigger by | Notify | Channel |
|------|----|-----------|--------|---------|
| needs-review | qa-passed | QA | PM | send-keys |
| needs-review | qa-failed | QA | PM | send-keys |
| needs-review | — | PM assigns | QA | send-keys + .task status |
```

2. **Gap detection**: If a transition has "Notify: —" and the next role is expected to just "know" — that's a gap.

3. **Channel reliability layers**:
   - **Primary**: Real-time (send-keys to tmux session) — immediately triggers the agent
   - **Secondary**: Persistent state (.task status, JSON status file) — survives session restarts
   - **Backup**: Issue comment / GitHub — survives everything but requires polling

4. **Common gaps found in practice**:
   - QA needs notification that a review is ready (PM sends send-keys vs QA polling .task files)
   - Review history must persist across rounds (shared JSON, not session-local)
   - "PM notifies" without a defined channel is a TODO, not a design

## Step 7 — Produce the structured review report

Write your report as an Issue Comment using this format:

```
## QA Review: Issue #{id} {title}

**审查对象**: {file list}
**审查 Agent**: @qa-agent
**审查时间**: {ISO8601}

**审查结论**: ✅ 通过 / ❌ 不通过 / ⚠️ 条件通过

---

### 审查清单

#### Section One: {dimension name}

| # | 验收项 | 状态 | 备注 |
|---|--------|------|------|
| 1 | {item} | ✅ / ⚠️ / ❌ | {evidence or cross-reference} |

(Repeat for each dimension)

---

### 未达标项清单

仅在不通过或条件通过时填写。逐条编号。

**#N — {brief title}**

- **问题描述**: {what's wrong}
- **位置**: {file:line or section}
- **建议**: {specific fix recommendation}

---

### 修改建议（非阻塞）

**建议 #N — {brief title}**

- **位置**: {file:line}
- **原因**: {why it matters}
- **建议**: {what to change}

---

### 整体评价

{1-3 sentence verdict, summary of strengths and remaining issues}
```

**Verdict rules:**
- ✅ **通过** — All checks pass, no inconsistencies, no missing stakeholder requirements
- ⚠️ **条件通过** — Minor issues (< 30 min total fix time) that don't block the design's core validity
- ❌ **不通过** — Found contradictions that fundamentally break the design, missing 30%+ stakeholder requirements, or blocked by unaddressed gaps

## Step 8 — Verify revisions (incremental)

When a v2 arrives:
1. Read the changelog / feedback integration table first
2. Verify only the items that were supposed to change
3. Confirm all your must-fix items (#1, #2, #3 from your previous report) are addressed
4. Check that fixing one issue didn't introduce new inconsistencies elsewhere

## Pitfalls

- **Design doc != code**. Don't check for compilation errors or test results. Check for internal consistency and feasibility.
- **Missing stakeholder requirements are invisible**. You must actively build a traceability table — you can't spot omissions by just reading the doc.
- **State machine diagrams lie**. They always look clean in the diagram. The contradictions live in the companion text or the usage rules.
- **"Conditional pass" is a lean tool**. Use it for minor issues to keep the design moving. Block only on foundational contradictions.
- **Template review catches different bugs than doc review**. A template can be syntactically correct but miss a key field, or reference a dead system. Read templates for coverage and legacy contamination, not just formatting.
- **Schema granularity is invisible in summaries**. A `qa_conclusion` field can technically exist but be useless if it's the only QA field — you need `findings` and `acceptance_results` at per-criterion granularity. Always check if the field set supports the full workflow, not just the reporting layer.
- **Write conflicts don't appear until deployment**. Two roles can each test their write independently and everything works. The conflict only surfaces when both write to the same file in the same sprint. You must catch this in the design phase by building a field ownership matrix.

## Related Skills

- `qa-acceptance-review` — Use AFTER implementation to verify task outputs. This skill (design-doc-review) is used BEFORE implementation.
