# Feature Matrix

## Purpose
- Track actual feature state in one place.
- Prevent humans and LLMs from guessing what exists, what is partial, and what is only planned.

## Usage Rules
- Update this file whenever feature status changes.
- Keep rows short and factual.
- Prefer `not_started`, `in_progress`, `partial`, `working`, `blocked`, `deferred`.
- Do not describe architecture here; link or point to the relevant docs instead.

## Current Core Features

| Feature | Status | Scope Note | Primary Docs |
| --- | --- | --- | --- |
| Godot project bootstrap | not_started | No gameplay project exists in repo yet | [first-playable-vertical-slice-execution-plan.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/first-playable-vertical-slice-execution-plan.md) |
| Main playable scene | not_started | First runnable scene for vertical slice | [first-playable-vertical-slice-execution-plan.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/first-playable-vertical-slice-execution-plan.md) |
| Player movement | not_started | XZ movement only for first slice | [movement-spec.md](d:/Game/DEV/iiWii/iiwii/docs/systems/movement-spec.md) |
| Simple player attack | not_started | Minimal attack only for first slice | [combat.md](d:/Game/DEV/iiWii/iiwii/docs/systems/combat.md) |
| Enemy navigation | not_started | Navmesh chase around obstacles | [enemy-ai-navigation-v1.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/ai/enemy-ai-navigation-v1.md) |
| Enemy death and HP | not_started | Minimal combat validation target | [combat.md](d:/Game/DEV/iiWii/iiwii/docs/systems/combat.md) |
| Traversal features | deferred | After first playable slice | [traversal-and-verticality.md](d:/Game/DEV/iiWii/iiwii/docs/systems/traversal-and-verticality.md) |
| Town/meta progression | deferred | Out of first slice scope | [town-meta-progression.md](d:/Game/DEV/iiWii/iiwii/docs/systems/town-meta-progression.md) |
| Inventory | deferred | Out of first slice scope | [inventory-system.md](d:/Game/DEV/iiWii/iiwii/docs/systems/inventory-system.md) |
| Multiplayer | deferred | Target-state only | [networking.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/networking.md) |

## Status Meanings
- `not_started`: no code exists yet
- `in_progress`: active implementation work is underway
- `partial`: some behavior exists, but the feature is not reliable or complete
- `working`: usable for the current milestone
- `blocked`: cannot proceed due to another missing dependency
- `deferred`: intentionally excluded from the current milestone
