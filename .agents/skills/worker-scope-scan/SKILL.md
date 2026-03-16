---
name: worker-scope-scan
description: "Internal worker skill for Boss Agent delegation when a task needs a fast, scope-sensitive implementation pre-scan. Use to interpret the request, narrow the real implementation scope, identify likely relevant files and entry points, map the probable implementation surface, and produce a minimal executable implementation plan without coding, review, regression checking, documentation updates, or repo-wide auditing."
visibility: hidden
agent_only: true
delegatable: true
worker_type: "planning"
boss_selectable: true
boss_priority: 10
---

# Purpose

Use this skill as an internal worker that the Boss Agent delegates to in the background.

This skill is not for direct user use and is not a standalone skill.

Use it near the start of a flow when an implementation-oriented task needs a fast scope scan before any coding begins.

Its job is to:
- interpret the task
- narrow the actual implementation scope
- separate likely out-of-scope items
- identify probable relevant files or file groups
- identify probable entry points
- map the affected area briefly
- produce a minimal actionable implementation plan

This worker is optimized for implementation-prep scope scanning, not for review-scope work. A future reviewer worker may also be scope-sensitive, but this skill should stay focused on pre-implementation narrowing.

# When To Use

Use this skill when:
- the Boss Agent needs a quick, narrow implementation pre-scan
- the request is implementable, but the concrete code surface is not yet clear
- the next step depends on finding the likely files, entry points, and affected area
- a short, deterministic scope pass can reduce context noise before handing off to `worker-implement`
- the task is still early enough that broad review or regression work would be premature

Typical use point:
- near the beginning of the flow
- after the Boss Agent has chosen to delegate
- before implementation starts

# When Not To Use

Do not use this skill when:
- the task is already fully scoped and ready for direct implementation
- the main need is code writing or code changes
- the main need is review, validation, or regression detection
- the request is primarily documentation-related
- the task requires a repo-wide audit or architecture-wide investigation
- the Boss Agent needs a final answer instead of a preparatory scope scan

# Input Expectations

Expected input from the Boss Agent:
- a short task statement or user request
- any already-known scope constraints
- optional hints about suspected files, systems, or folders
- optional notes about what must not be touched

If the input is incomplete, state that briefly and still produce the narrowest useful scope proposal possible.

# Scope Rules

Always:
1. restate the task briefly
2. narrow the real implementation scope
3. separate out-of-scope items explicitly
4. identify only the most likely relevant implementation surface

Scope rules:
- stay close to the requested task
- prefer a narrow, usable scope over a broad exploratory one
- do not expand into general architecture analysis
- do not scan the whole repository unless the task truly cannot be narrowed
- do not chase every possible dependency
- do not treat uncertainty as a reason to widen the scope aggressively

Repo-specific narrowing hints:
- start from `docs/README.md` when the user request is broad or feature-named
- use `docs/technical/feature-matrix.md` to confirm current implementation status before planning changes
- use `docs/architecture/code-map.md` to keep the implementation surface tight inside `godot/`
- prefer behavior-slice scope over open-ended prototype polish unless the user explicitly asks for wider cleanup

# Execution Policy

Preferred sequence:
1. interpret the task
2. resolve the likely implementation scope
3. identify probable relevant files or file groups
4. identify probable entry points
5. note the main risks or unknowns
6. produce a minimal implementation plan
7. suggest the next worker

Execution behavior:
- be fast
- be narrow
- be deterministic
- optimize for implementation readiness
- keep findings short and actionable
- surface uncertainty without turning it into an audit

Project-specific examples:
- for movement updates, the likely implementation surface is `godot/scripts/player/player_controller.gd` plus the directly related scene or movement docs
- for enemy melee or navigation updates, the likely implementation surface is `godot/scripts/enemy/enemy_controller.gd` and the smallest relevant file set under `godot/scripts/enemy/movement/`
- for projectile or attack behavior, the likely implementation surface is `godot/scripts/player/player_controller.gd`, `godot/scripts/projectiles/projectile.gd`, and directly related scene wiring
- for debug behavior, keep scope centered on `godot/scripts/debug/`, `godot/scripts/main/demo_main_controller.gd`, and the explicit debug slice docs

Do not:
- implement code
- perform a code review
- perform regression analysis
- update documentation
- archive anything
- broaden into a full repo assessment

# Output Contract

Return a structured output with exactly these sections:

- `task_goal`
- `resolved_scope`
- `relevant_files`
- `entry_points`
- `risks`
- `implementation_plan`
- `confidence`

Field expectations:
- `task_goal`: exactly 1 short sentence describing the practical implementation goal
- `resolved_scope`: 2-5 short bullet points naming the concrete implementation surface to target
- `relevant_files`: 1-8 likely files or folders only; prefer paths; do not produce exhaustive inventories
- `entry_points`: 1-5 likely starting files, classes, scenes, systems, or functions
- `risks`: 0-4 short bullet points covering only the main uncertainties or coupling risks
- `implementation_plan`: 2-5 short ordered steps that prepare the next worker to implement
- `confidence`: exactly one of `low`, `medium`, or `high`, optionally followed by a very short reason
- Human-readable field values should be in English. Field names and enum values must remain unchanged.

Formatting rules:
- keep every section compact
- prefer bullets over paragraphs except for `task_goal` and `confidence`
- do not add extra sections
- do not add narrative before or after the structured output
- if a section is uncertain, keep it narrow and mark it as likely rather than expanding scope

Keep the output compact and Boss-compatible.

# Guardrails

- Do not implement.
- Do not review.
- Do not run regression checks.
- Do not update documentation.
- Do not archive.
- Do not perform a full repo audit.
- Do not search for everything.
- Do not widen the scope on your own.
- Do not replace missing information with speculative architecture claims.
- If information is limited, say so briefly and still provide the narrowest usable scope suggestion.
- Avoid context pollution, long narratives, and unnecessary explanation.
