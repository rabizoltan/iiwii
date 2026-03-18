# Workplans

This folder contains implementation sequencing and delivery plans.

## Role
- These files are execution aids.
- They are not product source of truth.
- If a workplan conflicts with an ADR or active architecture/system doc, the ADR or active doc wins.
- A workplan is valid only if it references code, scenes, configs, and test assets that actually exist in the repo.

## Use Cases
- Breaking a feature into safe steps
- Tracking rollout order
- Capturing validation gates for implementation work

## Folder Layout
- `active/`: current execution plans that are still actionable once their blockers are cleared.
- `roadmaps/`: higher-level sequencing docs that point to multiple slices or future branches of work.
- `completed/`: closed slices and finished implementation plans kept as delivery history.
- `handoffs/`: session handoff documents for restart context.
- `stale/`: superseded plans kept only for historical context or link preservation.

## Status Rules
- `active`: the plan is the current execution guide for work that should proceed now.
- `blocked`: design intent is useful, but execution cannot start because required code/assets are not present yet.
- `stale`: no longer matches the current repo or current source-of-truth docs; rewrite or delete.

## Current Reality
- This repository now contains both active documentation and an early Godot 4.6 gameplay project under `godot/`.
- Workplans may reference implemented files that already exist here.
- If a workplan claims completed implementation progress on files that do not exist here, that plan must still be treated as `blocked` or `stale`, not as active progress.

## Current Focus
- Completed first playable Godot foundation slice
- Next work should move into behavior-specific slices, not open-ended prototype polishing

## Reusable Reference Ideas
- From an older architecture draft, the only reusable principles worth keeping are:
  - `Brain -> Navigation -> Motor -> Combat` separation
  - lower-frequency AI scheduling instead of full-frame decision spam
  - local crowd-readability policy on top of navmesh
  - event-driven presentation rather than gameplay logic in presentation
  - long-term data-driven content direction
- From an older bootstrap prototype brief, the only reusable execution idea worth keeping is:
  - if a first playable Godot slice is needed, keep it extremely small:
    - one scene
    - WASD movement
    - simple shooting
    - 2-3 enemies
    - navmesh chase
    - simple obstacle validation including a U-shape
  - use that kind of brief only as a bootstrap task prompt, never as project truth

## Current Workplans
- [active/combat-feedback-and-debug-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/active/combat-feedback-and-debug-behavior-slice.md): blocked execution plan pending explicit feedback-scope decisions.
- [roadmaps/behavior-slice-roadmap.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/roadmaps/behavior-slice-roadmap.md): planning entry point for the current behavior-slice sequence.
- [roadmaps/player-traversal-and-movement-slice-roadmap.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/roadmaps/player-traversal-and-movement-slice-roadmap.md): parent roadmap for future dodge/dash, vault, and crouch traversal slices.
- [completed/first-playable-vertical-slice-execution-plan.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/completed/first-playable-vertical-slice-execution-plan.md): completed foundation milestone that proved the first runnable gameplay slice.
- [completed/player-attack-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/completed/player-attack-behavior-slice.md): completed behavior slice for world-aimed player projectile attacks.
- [completed/debug-control-panel-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/completed/debug-control-panel-slice.md): completed shared debug control slice centered on the `F3` overlay.
- [completed/player-enemy-collision-and-crowd-pressure-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/completed/player-enemy-collision-and-crowd-pressure-slice.md): completed crowd-pressure baseline cleanup that removed baseline player shove.
- [completed/refactor-enemy-runtime-cleanup-and-boundary-tightening.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/completed/refactor-enemy-runtime-cleanup-and-boundary-tightening.md): completed runtime cleanup/refactor planning artifact.
- [handoffs/session-handoff-2026-03-08.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/handoffs/session-handoff-2026-03-08.md): latest session handoff baseline for restart context.
- [stale/enemy-close-range-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/stale/enemy-close-range-behavior-slice.md): stale historical slice note that now points to the renewed melee behavior source of truth.
