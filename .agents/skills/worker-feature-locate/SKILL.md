---
name: worker-feature-locate
description: "Internal worker skill for Boss Agent delegation when a user-mentioned feature must be located in the project. Use near the start of a pipeline to map a feature name to its likely subsystem, main implementation area, entry points, and related documentation while filtering out unnecessary context and avoiding broad repository analysis."
visibility: hidden
agent_only: true
delegatable: true
worker_type: "analysis"
boss_selectable: true
boss_priority: 4
---

# Purpose

Use this skill as an internal worker that the Boss Agent delegates to in the background.

This skill is not for direct user use and is not a standalone skill.

Use it typically near the start of the pipeline.

Its goal is to identify where a user-mentioned feature most likely lives in the system by:
- interpreting the feature name
- binding it to a likely subsystem
- finding the most likely code entry points
- identifying related documentation
- estimating the main implementation area

This worker only locates the feature. It does not implement, modify files, or refactor.

# Canonical Documentation Policy

Prefer top-level project documentation for orientation first.

Check the `docs/` folder for canonical documents, especially:
- `docs/README.md`
- `docs/technical/feature-matrix.md`
- `docs/technical/tuning-map.md`
- `docs/technical/validation-map.md`
- `docs/architecture/high-level-architecture.md`
- `docs/architecture/code-map.md`

If these exist:
- try to map the feature name to them
- identify the likely subsystem
- identify the likely feature family

These are orientation sources, not mandatory truth sources.

If code or other documentation provides a tighter or more current signal, prefer that.

In this repo, map feature names through these anchors when possible:
- `docs/technical/feature-matrix.md` for whether the feature is working, partial, blocked, or deferred
- `docs/technical/tuning-map.md` for where current tuning/config ownership lives
- `docs/technical/validation-map.md` for which scenes, fixtures, and checks currently validate the feature
- `docs/architecture/code-map.md` for likely runtime owners under `godot/`
- `docs/systems/` for player-facing rules such as movement, combat, progression, and extraction
- `docs/architecture/ai/` for enemy navigation, melee behavior, and runtime ownership

# When To Use

Use this worker when:
- the user speaks in feature terms
- the exact files are not known
- the implementation location of the feature is unclear
- the Boss Agent needs a fast feature-location pass

# When Not To Use

Do not use this worker when:
- the Boss Agent already has exact files
- the task is limited to a concrete known module
- the implementation location is already known

# Input Expectations

Expected input from the Boss Agent:
- the user-mentioned feature name or feature-oriented task
- optional hints about likely modules, systems, or docs
- optional constraints about irrelevant areas

If the input is incomplete, still produce the narrowest useful feature-location guess from the strongest available signals.

# Execution Policy

Preferred sequence:
1. interpret the feature name
2. try to bind it to a subsystem
3. check the core documentation
4. identify the most likely code entry points
5. identify the related files

Execution behavior:
- stay narrow
- avoid full repository analysis
- focus on the most likely implementation locations
- prefer verifiable signals over speculation
- keep the result concise and actionable

Project-specific examples:
- `player movement` should usually resolve to the movement subsystem, `docs/systems/movement-spec.md`, `docs/architecture/code-map.md`, `godot/scenes/player/Player.tscn`, and `godot/scripts/player/player_controller.gd`
- `enemy AI`, `enemy melee`, or `close-range behavior` should usually resolve to the enemy AI subsystem, relevant docs under `docs/architecture/ai/`, and `godot/scripts/enemy/`
- `debug control panel` should usually resolve to the debug/runtime tooling area, `docs/workplans/debug-control-panel-slice.md`, `godot/scenes/debug/DebugOverlay.tscn`, `godot/scripts/debug/debug_overlay.gd`, and `godot/scripts/main/demo_main_controller.gd`
- `enemy tuning`, `projectile tuning`, or `config ownership` should usually resolve through `docs/technical/tuning-map.md`, `docs/systems/tuning-and-stats.md`, and the relevant owning scripts under `godot/scripts/`
- `validation`, `test fixture`, or `how do we verify this` should usually resolve through `docs/technical/validation-map.md`, the relevant workplan, and the current demo-scene validation surface

# Output Contract

Return a structured output with exactly these sections:

- `feature_interpretation`
- `subsystem_guess`
- `primary_files`
- `secondary_files`
- `entry_points`
- `related_docs`
- `confidence`

Field expectations:
- `feature_interpretation`: exactly 1 short sentence
- `subsystem_guess`: exactly 1 subsystem
- `primary_files`: 1-6 file paths
- `secondary_files`: 0-8 file paths
- `entry_points`: 1-4 functions, classes, or modules
- `related_docs`: 0-4 documentation paths
- `confidence`: exactly one of `low`, `medium`, or `high`
- Human-readable field values should be in English. Field names and enum values must remain unchanged.

Formatting rules:
- keep every section compact
- prefer bullets over paragraphs except for `feature_interpretation`, `subsystem_guess`, and `confidence`
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
