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
| Main playable scene | working | Demo scene runs with player, enemies, navmesh obstacles, projectile anchor setup, and dedicated flat/elevated attack test fixtures | [first-playable-vertical-slice-execution-plan.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/first-playable-vertical-slice-execution-plan.md) |
| Player movement | working | Player movement is responsive and obstacle-safe in the first demo scene | [movement-spec.md](d:/Game/DEV/iiWii/iiwii/docs/systems/movement-spec.md) |
| Simple player attack | working | Mouse/world aimed projectile shots enforce one-click single-shot, `0.5s` cooldown, blocker-aware travel, and validated elevated/ground/enemy targeting in the demo scene | [combat.md](d:/Game/DEV/iiWii/iiwii/docs/systems/combat.md) |
| Enemy navigation | partial | Current runtime covers single-target melee approach-goal selection, explicit `approach -> close_adjust -> melee_hold` state handling, stable hold/facing, and minimal stuck fallback; broader v1 crowd behavior, threat selection, ranged logic, and expanded fixtures remain incomplete | [enemy-ai-navigation-v1.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/ai/enemy-ai-navigation-v1.md) |
| Enemy death and HP | partial | HP display, damage, and death exist; final verification and feel tuning still pending | [combat.md](d:/Game/DEV/iiWii/iiwii/docs/systems/combat.md) |
| Player attack behavior slice | working | Mouse/world aim, no-fire gating, blocker-aware projectile travel, and demo-scene validation are complete for the current slice scope | [player-attack-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/player-attack-behavior-slice.md) |
| Debug control panel slice | working | `F3` debug menu exposes shared toggles for enemy status, enemy nav path, and projectile debug lines for runtime validation in the demo scene | [debug-control-panel-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/debug-control-panel-slice.md) |
| Enemy close-range melee behavior slice | in_progress | The rebuild now includes an explicit melee state machine, approach goal caching, local close-adjust movement, stable melee hold by distance envelope, and clearer debug state output; soft spreading, crowd-yield, and dense-crowd validation are not complete yet | [enemy-close-range-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/enemy-close-range-behavior-slice.md) |
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
