---
name: worker-navmesh-diagnose
description: "Internal worker skill for Boss Agent delegation when a task needs focused diagnosis of navmesh, enemy pathing, reachability, or navigation-setup problems. Use near the start of an enemy-navigation diagnostic chain to identify likely failure modes, likely owner files, scene/setup risks, and the smallest sensible next worker without implementing a fix."
visibility: hidden
agent_only: true
delegatable: true
worker_type: "diagnostics"
boss_selectable: true
boss_priority: 16
---

# Purpose

Use this skill as an internal worker that the Boss Agent delegates to in the background.

This skill is not for direct user use and is not a standalone skill.

Use it when the task is about navmesh, enemy navigation, pathfinding, crowding, stuck behavior, invalid goal selection, or scene-side navigation setup.

Its goal is to diagnose the most likely navigation failure mode before implementation begins.

This worker should:
- identify the likely navigation target or symptom
- map the most likely owner files and docs
- separate code-side risks from scene/setup risks
- call out likely tuning culprits
- suggest the smallest useful next worker

This worker is a diagnosis worker, not a fix worker.

# When To Use

Use this worker when:
- enemies get stuck, jitter, oscillate, or fail to reach the player
- pathing appears wrong, overly expensive, or inconsistent
- navmesh layer, reachability, or region assumptions may be incorrect
- enemy movement behavior and scene navigation setup may be out of sync
- the Boss Agent needs a tight diagnosis before asking for instrumentation or implementation

Typical use point:
- near the start of a diagnostic flow
- after `worker-feature-locate` or `worker-context-map` when the problem is clearly navigation-related

# When Not To Use

Do not use this worker when:
- the task is already narrowed to a concrete code change
- the main need is generic responsiveness diagnosis
- the task is about player movement rather than enemy navigation
- the request is mainly documentation maintenance
- a fix has already been chosen and implementation should start

# Canonical Documentation Policy

Use top-level documentation for orientation first, then tighten against the nearest code and scene truth.

Prefer these project anchors when relevant:
- `docs/README.md`
- `docs/technical/feature-matrix.md`
- `docs/technical/tuning-map.md`
- `docs/technical/validation-map.md`
- `docs/architecture/code-map.md`
- `docs/architecture/ai/enemy-ai-navigation-v1.md`
- `docs/architecture/ai/enemy-melee-behavior-v1.md`
- `docs/architecture/ai/enemy-ai-testplan-v1.md`
- `docs/architecture/ai/enemy-movement-runtime-ownership.md`
- `docs/decisions/ADR-016-space-model-continuous-world-navmesh-no-tile-diagonals.md`
- `docs/decisions/ADR-017-navmesh-size-layers.md`
- `docs/decisions/ADR-018-enemy-ai-nav-v1-approach.md`

Project-specific interpretation hints:
- use `feature-matrix.md` to confirm whether the navigation slice is active, partial, or experimental
- use `tuning-map.md` to identify where movement and chase tuning lives today
- use `validation-map.md` to identify the current demo-scene validation surface
- use `code-map.md` to keep the diagnosis surface tight inside `godot/`
- use the AI architecture docs and ADRs to distinguish intended design from current runtime drift

# Code And Scene Focus

Prefer the smallest realistic file set first.

In this repo, likely primary surfaces include:
- `godot/scenes/main/DemoMain.tscn`
- `godot/scenes/enemy/EnemyBasic.tscn`
- `godot/scripts/enemy/enemy_controller.gd`
- `godot/scripts/enemy/movement/enemy_navigation_locomotion.gd`
- `godot/scripts/enemy/movement/enemy_goal_selector.gd`
- `godot/scripts/enemy/movement/enemy_movement_state_machine.gd`
- `godot/scripts/enemy/movement/enemy_close_state.gd`
- `godot/scripts/enemy/movement/enemy_crowd_query.gd`
- `godot/scripts/enemy/movement/enemy_crowd_response.gd`
- `godot/scripts/enemy/movement/enemy_movement_influence.gd`
- `godot/scripts/enemy/state/enemy_runtime_state.gd`
- `godot/scripts/enemy/debug/enemy_debug_telemetry.gd`
- `godot/scripts/enemy/debug/enemy_debug_snapshot.gd`
- `godot/scripts/enemy/debug/enemy_debug_snapshot_builder.gd`

Scene/setup issues to consider explicitly:
- missing or mismatched navigation region assumptions
- wrong nav layer or mask usage
- agent radius or size mismatch against the intended world scale
- unreachable engage positions
- invalid local avoidance assumptions
- demo-scene setup drift from documented expectations

# Input Expectations

Expected input from the Boss Agent:
- a short description of the navigation symptom
- optional hints about the affected enemy type, scene, or docs
- optional known files or recent changes

If the input is incomplete, still produce the narrowest useful diagnosis from the strongest available signals.

# Execution Policy

Preferred sequence:
1. restate the navigation symptom briefly
2. identify the likely navigation target or failure class
3. identify the smallest likely code and scene surface
4. separate likely scene/setup risks from likely code/tuning risks
5. identify the most plausible failure modes
6. suggest the smallest useful next worker

Execution behavior:
- stay diagnostic, not implementational
- prefer likely causes over exhaustive enumeration
- keep the analysis tight to enemy navigation
- use repo-specific docs and scenes, not generic Godot advice
- surface uncertainty without turning the task into a repo-wide audit

Typical failure modes to consider:
- corner or obstacle sticking
- unreachable or poor goal selection
- repath churn or oscillation
- crowd pressure deadlock near the player
- layer or size mismatch between scene assumptions and runtime movement
- movement-state drift between controller, locomotion, and close-range logic

Do not:
- implement fixes
- broaden into a full AI redesign
- perform a general regression audit
- rewrite documentation
- run a full project-wide architecture review

# Output Contract

Return a structured output with exactly these sections:

- `navigation_target`
- `suspected_failure_modes`
- `primary_surfaces`
- `scene_or_setup_risks`
- `code_or_tuning_risks`
- `recommended_validation_points`
- `confidence`
- `recommended_next_worker (Continue? Say if you prefer no worker.)`

Field expectations:
- `navigation_target`: exactly 1 short sentence describing the symptom class
- `suspected_failure_modes`: 2-5 short bullets
- `primary_surfaces`: 3-8 concrete file paths
- `scene_or_setup_risks`: 1-4 short bullets
- `code_or_tuning_risks`: 1-4 short bullets
- `recommended_validation_points`: 2-5 short bullets tied to this repo's scenes, debug surfaces, or docs
- `confidence`: `low`, `medium`, or `high`
- `recommended_next_worker (Continue? Say if you prefer no worker.)`: exactly one of `worker-observability-setup`, `worker-scope-scan`, `worker-extend-feature`, `worker-refactor`, or `none`

# Handoff Guidance

Choose the next worker based on the dominant need:
- use `worker-observability-setup` when the failure mode is plausible but not yet observable enough
- use `worker-scope-scan` when the likely fix surface is known well enough to prepare implementation
- use `worker-extend-feature` when the diagnosis points to a missing guard, fallback, or behavior branch
- use `worker-refactor` when the failure looks caused by local structural confusion rather than missing behavior
- use `none` when the diagnosis is already sufficient for a direct Boss synthesis
