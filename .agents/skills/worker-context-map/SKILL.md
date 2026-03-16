---
name: worker-context-map
description: "Internal worker skill for Boss Agent delegation when a task needs a fast context map. Use near the start of a pipeline to identify likely relevant files, entry points, subsystems, and early call-chain surfaces while filtering out unnecessary context. Prefer top-level canonical Docs for orientation when useful, but treat nearby code and narrower local documentation as the primary source when they provide a tighter truth."
visibility: hidden
agent_only: true
delegatable: true
worker_type: "analysis"
boss_selectable: true
boss_priority: 5
---

# Purpose

Use this skill as an internal worker that the Boss Agent delegates to in the background.

This skill is not for direct user use and is not a standalone skill.

Use it typically near the start of the pipeline.

Its purpose is to produce a fast context map for the Boss by:
- identifying likely relevant files and modules
- finding the most likely entry points
- mapping the initial part of the call chain
- identifying the affected subsystem
- filtering out unnecessary context

This worker only builds a context map. It does not implement, refactor, review, or run regression analysis.

# Canonical Documentation Policy

Prefer top-level project documentation for orientation first.

Check the `docs/` folder for canonical documents, especially:
- `docs/README.md`
- `docs/technical/feature-matrix.md`
- `docs/technical/tuning-map.md`
- `docs/technical/validation-map.md`
- `docs/architecture/high-level-architecture.md`
- `docs/architecture/code-map.md`

If these exist, use them for rapid system orientation.

These are orientation sources, not mandatory truth sources.

If they are missing, not relevant, or the nearby code provides a tighter truth, prefer the code and close local documentation.

In this repo, these anchors are especially useful:
- `docs/README.md` for the reading order and current project framing
- `docs/technical/feature-matrix.md` for actual feature status
- `docs/technical/tuning-map.md` for current tuning/config ownership
- `docs/technical/validation-map.md` for reusable validation entry points and fixtures
- `docs/architecture/code-map.md` for runtime ownership under `godot/`
- subsystem docs under `docs/architecture/ai/` and `docs/systems/` for enemy AI, movement, combat, and debug behavior slices

# When To Use

Use this worker when:
- the task may affect multiple modules
- the relevant files are not yet clear
- the feature location is unknown
- the system is complex
- the Boss Agent needs a fast context map

# When Not To Use

Do not use this worker when:
- the Boss Agent already has the exact files
- the task is limited to a single known file
- the context is already clear enough

# Input Expectations

Expected input from the Boss Agent:
- the task or task goal
- optional hints about suspected files, systems, or features
- optional constraints about what areas are likely irrelevant

If the input is incomplete, still produce the narrowest useful context map from the most likely surfaces.

# Execution Policy

Preferred sequence:
1. restate the task goal briefly
2. try to bind the task to a subsystem
3. identify the most likely entry points
4. identify the primary and secondary files
5. note the likely side-effect areas

Execution behavior:
- stay narrow
- avoid full repository analysis
- map only the most likely relevant areas
- prefer verifiable context over speculation
- keep the result compact and actionable

Project-specific examples:
- movement or traversal tasks should usually start from `docs/systems/movement-spec.md`, `docs/systems/traversal-and-verticality.md`, and `godot/scripts/player/player_controller.gd`
- enemy AI or melee behavior tasks should usually start from `docs/architecture/ai/`, `docs/technical/feature-matrix.md`, `docs/architecture/code-map.md`, and `godot/scripts/enemy/`
- combat or projectile tasks should usually start from `docs/systems/combat.md`, `godot/scripts/player/player_controller.gd`, and `godot/scripts/projectiles/projectile.gd`
- tuning or config-ownership tasks should usually start from `docs/technical/tuning-map.md`, `docs/systems/tuning-and-stats.md`, and the owning runtime scripts under `godot/scripts/`
- validation or test-fixture tasks should usually start from `docs/technical/validation-map.md`, the relevant slice workplan, and `godot/scenes/main/DemoMain.tscn`
- debug menu or runtime observability tasks should usually start from `docs/workplans/debug-control-panel-slice.md`, `godot/scripts/debug/debug_overlay.gd`, and `godot/scripts/main/demo_main_controller.gd`

# Output Contract

Return a structured output with exactly these sections:

- `task_interpretation`
- `primary_files`
- `secondary_files`
- `entry_points`
- `subsystems`
- `likely_side_effects`
- `confidence`

Field expectations:
- `task_interpretation`: exactly 1 short sentence
- `primary_files`: 1-6 file paths
- `secondary_files`: 0-8 file paths
- `entry_points`: 1-4 functions, classes, or modules
- `subsystems`: 1-4 subsystem names
- `likely_side_effects`: 0-4 short bullet points
- `confidence`: exactly one of `low`, `medium`, or `high`
- Human-readable field values should be in English. Field names and enum values must remain unchanged.

Formatting rules:
- keep every section compact
- prefer bullets over paragraphs except for `task_interpretation` and `confidence`
- do not add extra sections
- do not add narrative before or after the structured output

Keep the output compact and Boss-compatible.

# Guardrails

- Do not implement code.
- Do not modify files.
- Do not refactor.
- Do not run regression analysis.
- Do not try to map the entire system.
- Avoid speculative guessing.
- Stay concise and targeted.
