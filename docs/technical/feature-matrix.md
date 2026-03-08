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
| Godot project bootstrap | working | Godot 4.6 project opens and runs with the initial slice scene | [first-playable-vertical-slice-execution-plan.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/first-playable-vertical-slice-execution-plan.md) |
| Main playable scene | working | Demo scene runs with player, enemies, navmesh obstacles, and projectile anchor setup | [first-playable-vertical-slice-execution-plan.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/first-playable-vertical-slice-execution-plan.md) |
| Player movement | working | Player movement is responsive and obstacle-safe in the first demo scene | [movement-spec.md](d:/Game/DEV/iiWii/iiwii/docs/systems/movement-spec.md) |
| Simple player attack | partial | Projectile attack exists and can be validated in-scene; combat feel still needs tuning | [combat.md](d:/Game/DEV/iiWii/iiwii/docs/systems/combat.md) |
| Enemy navigation | partial | Enemies chase, hold near the player, and recover from simple stuck cases, but routing is still prototype-grade | [enemy-ai-navigation-v1.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/ai/enemy-ai-navigation-v1.md) |
| Enemy death and HP | partial | HP display, damage, and death exist; final verification and feel tuning still pending | [combat.md](d:/Game/DEV/iiWii/iiwii/docs/systems/combat.md) |
| Player attack behavior slice | in_progress | Behavior rules are now locked and the next implementation work should start from the dedicated slice plan | [player-attack-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/player-attack-behavior-slice.md) |
| Enemy close-range melee behavior slice | not_started | Baseline melee close-range behavior is specified, but implementation should start only after the attack behavior slice is validated | [enemy-close-range-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/enemy-close-range-behavior-slice.md) |
| Combat feedback and debug behavior slice | blocked | Wait until player attack and melee close-range behavior are implemented and validated | [combat-feedback-and-debug-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/combat-feedback-and-debug-behavior-slice.md) |
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
