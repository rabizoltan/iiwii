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
- `active`: references existing repo assets and can be executed now.
- `blocked`: design intent is useful, but execution cannot start because required code/assets are not present yet.
- `stale`: no longer matches the current repo or current source-of-truth docs; rewrite or delete.

## Current Reality
- This repository currently contains documentation only.
- If a workplan references a missing `godot/` tree or claims implementation progress on files that do not exist here, that plan must be treated as `blocked` or `stale`, not as active progress.

## Current Focus
- First playable Godot vertical slice
- Hero movement, basic combat, and enemy navigation foundation

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

## Active Workplan
- [first-playable-vertical-slice-execution-plan.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/first-playable-vertical-slice-execution-plan.md): active execution plan for the first actual programming work.
