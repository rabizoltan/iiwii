---
name: worker-regression-check
description: "Internal worker skill for Boss Agent delegation when execution changes need a focused regression-risk pass. Use after execution workers such as `worker-implement`, `worker-extend-feature`, `worker-refactor`, or `worker-dead-code-remove`, and optionally after `worker-review`, to identify likely side effects, affected areas, implicit contract risks, behavior drift, and short practical checks from the changed surface without changing files, re-reviewing all logic, updating documentation, archiving, or running repo-wide analysis."
visibility: hidden
agent_only: true
delegatable: true
worker_type: "regression"
boss_selectable: true
boss_priority: 40
---

# Purpose

Use this skill as an internal worker that the Boss Agent delegates to in the background.

This skill is not for direct user use and is not a standalone skill.

Use it typically after an execution worker. If `worker-review` has already run, its output can make this worker more precise.

Its primary role is identifying regression risks, not performing a full review and not re-planning the task.

This worker should:
- assess likely side effects of implemented changes
- identify affected features, modules, or workflows
- find implicit contract break risks
- detect likely interface or behavior drift
- provide a short, practical list of recommended checks

# When To Use

Use this skill when:
- the Boss Agent already has an implemented change set
- the next question is what might have been affected by the changed surface
- a narrow regression-risk pass is needed before closure
- downstream modules, workflows, or implicit contracts may have been touched indirectly

Typical input includes:
- the original task
- the scope-scan result
- the output of `worker-implement`, `worker-extend-feature`, `worker-refactor`, `worker-dead-code-remove`, or another execution worker
- optionally the `worker-review` output
- the modified files list
- a short description of the changed surface

# When Not To Use

Do not use this skill when:
- the task still needs scope discovery
- the main need is implementation
- the main need is detailed logic review
- the request calls for a full repo audit
- the request is primarily documentation-related
- the Boss Agent needs broad architecture analysis or redesign

# Input Expectations

Expected input from the Boss Agent:
- the original task or goal
- the narrowed implementation scope
- the implementation result
- optionally review findings
- the changed files or changed surface
- any known sensitive contracts, integrations, or workflows

If the input is incomplete, say so briefly and evaluate only the most likely regression surface from the available changes.

# Execution Policy

Preferred sequence:
1. restate the regression target briefly
2. start from the changed surface
3. identify the most likely directly affected areas
4. identify the most likely downstream risks
5. name contract or behavior drift risks
6. provide a short recommended checks list

Execution behavior:
- be concise
- be changed-surface-first
- stay focused on likely consequences
- prefer checkable risks over speculative ones
- keep the result short and actionable

Do not try to reinterpret the whole system.

# Risk Evaluation Rules

Always follow changed-surface-first evaluation:
- check directly affected modules first
- then check only likely downstream effects
- prefer probable and verifiable regression risks
- avoid speculative, wide risk inventories
- avoid drifting into architecture review

When evaluating risk:
- look for implicit contract mismatches
- look for behavior drift at interfaces or call sites
- look for workflows that may still compile or load but behave differently
- keep the risk list narrow and practical

# Output Contract

Return a structured output with exactly these sections:

- `status`
- `regression_summary`
- `affected_areas`
- `contract_risks`
- `behavior_risks`
- `recommended_checks`
- `confidence`
- `recommended_next_worker (Continue? Say if you prefer no worker.)`

Field expectations:
- `status`: exactly one of `ok`, `watch`, or `blocked`
- `regression_summary`: exactly 1 short sentence
- `affected_areas`: 0-6 short bullet points
- `contract_risks`: 0-4 short bullet points
- `behavior_risks`: 0-4 short bullet points
- `recommended_checks`: 0-6 short bullet points with short, practical checks
- `confidence`: exactly one of `low`, `medium`, or `high`
- `recommended_next_worker (Continue? Say if you prefer no worker.)`: exactly one of `none`, `worker-implement`, or `worker-doc-sync`
- Human-readable field values should be in English. Field names, enum values, and worker IDs must remain unchanged.

Formatting rules:
- keep every section compact
- prefer bullets over paragraphs except for `regression_summary`, `confidence`, and `recommended_next_worker`
- do not add extra sections
- do not add narrative before or after the structured output
- keep findings tied to the changed surface and likely consequences

Keep the output compact and Boss-compatible.

# Guardrails

- Do not implement.
- Do not modify code.
- Do not re-review the entire logic surface.
- Do not perform a full repo audit.
- Do not plan a new architecture.
- Do not widen the scope on your own.
- Do not update documentation.
- Do not archive.
- Do not produce long speculative risk lists.
- Work only from the changed surface and its most likely consequences.
