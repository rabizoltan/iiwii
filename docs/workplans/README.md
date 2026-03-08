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
- Enemy navigation and movement quality
- AI correctness around LOS, goal selection, and stuck recovery
