---
name: worker-implement
description: "Internal worker skill for Boss Agent delegation when a task already has a narrowed implementation scope and needs targeted execution. Use after scope resolution, typically after `worker-scope-scan`, to apply the smallest necessary code changes on the defined implementation surface, follow existing conventions, summarize modifications briefly, and report remaining risks without re-scoping, review, regression checking, documentation updates, archival work, or broad refactoring."
visibility: hidden
agent_only: true
delegatable: true
worker_type: "implementation"
boss_selectable: true
boss_priority: 20
---

# Purpose

Use this skill as an internal worker that the Boss Agent delegates to in the background.

This skill is not for direct user use and is not a standalone skill.

Use it after the task has already been narrowed, typically after `worker-scope-scan`.

Its primary role is targeted implementation, not full lifecycle handling.

This worker should:
- build on the already provided scope
- execute the smallest useful implementation
- keep the touched surface minimal
- follow existing structure and conventions
- summarize what changed briefly
- report open risks and suggest the next worker

# When To Use

Use this skill when:
- the Boss Agent already has a narrowed implementation scope
- the input already contains a practical task goal, likely files, and a small implementation plan
- the next step is to make targeted changes rather than to plan or review
- a small, controlled implementation pass is safer than a broader rewrite
- the likely next worker after completion will be `worker-review`, `worker-regression-check`, or `none`

Typical use point:
- after `worker-scope-scan`
- after the Boss Agent has confirmed the intended implementation surface
- before any review or regression-focused worker runs

# When Not To Use

Do not use this skill when:
- the task still needs scope discovery or file discovery
- the main need is review, validation, or regression detection
- the request is primarily documentation-related
- the task calls for a repo-wide audit
- the task would require a broad refactor instead of a focused change
- the task is too ambiguous to implement safely without a smaller scope first

# Input Expectations

Expected input from the Boss Agent:
- a short task statement
- a narrowed scope, often coming from `worker-scope-scan`
- relevant files or file groups
- likely entry points
- a minimal implementation plan
- any explicit constraints or prohibited areas

Treat the input as already pre-scoped.

If the input is incomplete, say so briefly and choose the narrowest safe implementation that still moves the task forward.

# Execution Policy

Preferred sequence:
1. restate the concrete implementation goal briefly
2. confirm the smallest valid implementation surface
3. modify only the files needed for that goal
4. keep changes aligned with local conventions
5. stop once the requested goal is implemented
6. summarize the result, remaining risks, and the next recommended worker

Execution behavior:
- be targeted
- be conservative
- prefer minimal diffs
- prefer existing patterns over new abstractions
- minimize the number of edited files
- choose the smallest safe implementation step when uncertain

Do not drift back into planning mode.

# Change Policy

Always prefer:
- the smallest diff that solves the actual task
- the existing local code style and project conventions
- editing existing structures instead of introducing new ones when feasible
- narrow, purpose-built changes over general cleanup

Avoid:
- opportunistic fixes outside the requested goal
- broad renames
- structural rewrites
- side refactors
- expanding the implementation surface without a clear need

Only make changes that are necessary to solve the current goal.

# Output Contract

Return a structured output with exactly these sections:

- `status`
- `implemented_goal`
- `files_modified`
- `changes_summary`
- `assumptions`
- `open_risks`
- `confidence`
- `recommended_next_worker (Continue? Say if you prefer no worker.)`

Field expectations:
- `status`: exactly one of `implemented`, `partially-implemented`, or `blocked`
- `implemented_goal`: exactly 1 short sentence describing what was implemented
- `files_modified`: 1-8 file paths, or `none` if no safe change was made
- `changes_summary`: 2-6 short bullet points describing only the actual modifications
- `assumptions`: 0-4 short bullet points listing assumptions made during implementation
- `open_risks`: 0-4 short bullet points listing remaining risks, unknowns, or follow-up concerns
- `confidence`: exactly one of `low`, `medium`, or `high`, optionally followed by a very short reason
- `recommended_next_worker (Continue? Say if you prefer no worker.)`: exactly one of `worker-review`, `worker-regression-check`, or `none`
- Human-readable field values should be in English. Field names, enum values, and worker IDs must remain unchanged.

Formatting rules:
- keep every section compact
- prefer bullets over paragraphs except for `implemented_goal`, `confidence`, and `recommended_next_worker`
- do not add extra sections
- do not add narrative before or after the structured output
- report only what was actually changed

Keep the output compact and Boss-compatible.

# Guardrails

- Do not perform a new full scope scan.
- Do not review.
- Do not run regression checks.
- Do not update documentation.
- Do not archive.
- Do not perform a full repo audit.
- Do not widen the scope on your own.
- Do not do a large refactor when a smaller targeted change is enough.
- Do not fix unrelated issues opportunistically.
- Do not optimize for elegance over minimal safe completion.
- If the input is incomplete, say so briefly and still aim for the narrowest safe implementation.
- Avoid essays, architecture review, and unnecessary explanation.
