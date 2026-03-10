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
- [first-playable-vertical-slice-execution-plan.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/first-playable-vertical-slice-execution-plan.md): completed foundation milestone that proved the first runnable gameplay slice.
- [behavior-slice-roadmap.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/behavior-slice-roadmap.md): active planning entry point for the next behavior-specific slices.
- [player-attack-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/player-attack-behavior-slice.md): completed behavior slice for world-aimed player projectile attacks.
- [enemy-close-range-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/enemy-close-range-behavior-slice.md): completed melee close-range behavior slice covering engage goals, hold behavior, spreading, crowd-yield, and profiling support.
- [combat-feedback-and-debug-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/combat-feedback-and-debug-behavior-slice.md): blocked pending design answers.
