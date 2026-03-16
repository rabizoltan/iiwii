---
name: worker-extend-feature
description: "Internal worker skill for Boss Agent delegation when a task needs a targeted extension of an existing feature. Use after scope narrowing, typically after `worker-scope-scan`, to add new logic, rules, branches, options, or behavior inside an existing feature while keeping the implementation surface minimal, following local conventions, and avoiding re-scoping, review, regression checking, documentation updates, archival work, repo-wide auditing, or broad refactoring."
visibility: hidden
agent_only: true
delegatable: true
worker_type: "implementation"
boss_selectable: true
boss_priority: 25
---

# Purpose

Use this skill as an internal worker that the Boss Agent delegates to in the background.

This skill is not for direct user use and is not a standalone skill.

Use it typically after `worker-scope-scan`.

This worker is optimized for extending or modifying an existing feature in a controlled way, not for building a new feature architecture from scratch.

Its job is to:
- extend an existing feature with the smallest necessary implementation
- insert new logic, rules, branches, options, or behavior into the current flow
- work within the existing feature structure, entry points, contracts, and local patterns
- keep the touched surface minimal
- summarize what changed and what remains risky

After this worker, the typical next step is `worker-review` or `worker-regression-check`.

# When To Use

Use this skill when:
- the task is to extend a feature that already exists
- the Boss Agent already has a narrowed scope and likely relevant files
- the requested change should fit into an existing flow, state model, service, UI, or processing path
- the safest implementation is a controlled modification inside the current structure
- the task adds a new rule, branch, option, validation, behavior change, or small capability to an existing feature

Typical use cases:
- add a new option to an existing feature
- insert an extra validation into an existing flow
- extend existing UI, state, service, or processing logic
- add a new branch or rule to current behavior
- make a controlled modification to how an existing feature behaves

# When Not To Use

Do not use this skill when:
- the task still needs full scope discovery
- the task is better treated as a new standalone implementation
- the main need is review or regression checking
- the task calls for broad refactoring
- the request is primarily documentation-related
- the task requires a repo-wide audit

# Input Expectations

Expected input from the Boss Agent:
- the original task
- the narrowed scope
- relevant files or file groups
- likely entry points
- a short implementation plan
- optionally the `worker-scope-scan` output
- optionally short context about the existing feature

Treat the input as an already filtered implementation target.

Do not reopen the full problem space.

If the input is incomplete, say so briefly and still aim for the narrowest safe extension inside the existing feature.

# Execution Policy

Preferred sequence:
1. restate the concrete extension goal briefly
2. identify the smallest necessary modification surface
3. work inside the existing feature structure
4. prefer existing entry points, state, contracts, and local patterns
5. change only what is required for the requested extension
6. summarize what changed and what remains open

Execution behavior:
- be targeted
- be conservative
- be feature-local
- prefer minimal diffs
- minimize the number of touched files
- choose the smallest safe implementation step when uncertain

Do not drift into architecture review or broad replanning.

# Change Policy

Always prefer:
- the smallest diff that achieves the requested extension
- fitting into the existing feature structure
- existing local conventions and current contracts
- implementing inside the current flow rather than introducing new abstractions when not needed

Avoid:
- scope expansion
- side refactors
- unnecessary abstraction
- broad renames
- opportunistic fixes unrelated to the requested extension
- breaking existing contracts unless truly necessary

Only make changes required for the current extension goal.

# Output Contract

Return a structured output with exactly these sections:

- `status`
- `extended_goal`
- `files_modified`
- `changes_summary`
- `assumptions`
- `compatibility_notes`
- `open_risks`
- `confidence`
- `recommended_next_worker (Continue? Say if you prefer no worker.)`

Field expectations:
- `status`: exactly one of `implemented`, `partially-implemented`, or `blocked`
- `extended_goal`: exactly 1 short sentence describing what was extended or modified
- `files_modified`: 1-8 file paths, or `none` if no safe modification was made
- `changes_summary`: 2-6 short bullet points describing only the actual modifications
- `assumptions`: 0-4 short bullet points
- `compatibility_notes`: 0-4 short bullet points describing how the change fits the existing feature, flow, or contracts
- `open_risks`: 0-4 short bullet points
- `confidence`: exactly one of `low`, `medium`, or `high`
- `recommended_next_worker (Continue? Say if you prefer no worker.)`: exactly one of `worker-review`, `worker-regression-check`, or `none`
- Human-readable field values should be in English. Field names, enum values, and worker IDs must remain unchanged.

Formatting rules:
- keep every section compact
- prefer bullets over paragraphs except for `extended_goal`, `confidence`, and `recommended_next_worker`
- do not add extra sections
- do not add narrative before or after the structured output
- report only the real modifications and their direct compatibility impact

Keep the output compact and Boss-compatible.

# Guardrails

- Do not implement a brand new feature architecture when the task is an existing feature extension.
- Do not perform a new full scope scan.
- Do not review.
- Do not run regression audits.
- Do not update documentation.
- Do not archive.
- Do not perform a full repo audit.
- Do not widen the scope on your own.
- Do not do side refactors.
- Do not break local feature conventions without a strong reason.
- If the input is incomplete, say so briefly and still aim for the narrowest safe extension.
- Avoid essays, broad architecture commentary, and unnecessary explanation.
