# Feature Matrix
Category: Runtime System
Role: Runtime Truth
Last updated: 2026-03-30
Last validated: pending

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
| Godot project bootstrap | working | Godot 4.6 project opens and runs with the initial slice scene | [first-playable-vertical-slice-execution-plan.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/completed/first-playable-vertical-slice-execution-plan.md) |
| Main playable scene | working | Demo scene runs with player, enemies, navmesh obstacles, projectile anchor setup, and dedicated flat/elevated attack test fixtures | [first-playable-vertical-slice-execution-plan.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/completed/first-playable-vertical-slice-execution-plan.md) |
| Camera control and framing | working | A reusable gameplay camera scene now provides soft-follow framing, middle-mouse rotation, constrained zoom, and camera-relative movement; playable maps should instance it and point `target_path` at the player, and the current baseline is manually validated and accepted | [camera-and-framing.md](d:/Game/DEV/iiWii/iiwii/docs/systems/camera-and-framing.md), [camera-rotation-and-zoom-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/completed/camera-rotation-and-zoom-slice.md) |
| Player movement | working | Player movement is responsive and obstacle-safe in the first demo scene | [movement-spec.md](d:/Game/DEV/iiWii/iiwii/docs/systems/movement-spec.md) |
| Player mobility foundation | partial | `Shift` still drives one shared mobility action with tunable `dodge` and `dash` profiles, cooldown, travel lock, and temporary enemy-body ghosting; class specialization and authored effect follow-ups remain out of scope | [movement-spec.md](d:/Game/DEV/iiWii/iiwii/docs/systems/movement-spec.md), [player-mobility-foundation-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/completed/player-mobility-foundation-slice.md) |
| Player vault traversal | working | `Space` now triggers authored low-obstacle vault traversal through `VaultTrigger` affordances, landing validation, committed traversal motion, enemy ghosting during travel, and long-obstacle `STRIP_OFFSET` support | [movement-spec.md](d:/Game/DEV/iiWii/iiwii/docs/systems/movement-spec.md), [traversal-and-verticality.md](d:/Game/DEV/iiWii/iiwii/docs/systems/traversal-and-verticality.md), [player-vault-traversal-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/completed/player-vault-traversal-slice.md) |
| Simple player attack | working | Mouse/world aimed projectile shots enforce one-click single-shot, `0.5s` cooldown, blocker-aware travel, and validated elevated/ground/enemy targeting in the demo scene | [combat.md](d:/Game/DEV/iiWii/iiwii/docs/systems/combat.md) |
| Runtime spawn warm-up | working | DemoMain now prewarms gameplay-critical spawned scenes through a shared warm-up manager so first-use projectile and debug-line spawns do not hitch; future combat/effect/enemy spawnables should register through the same scene-level path | [godot-conventions.md](d:/Game/DEV/iiWii/iiwii/docs/technical/godot-conventions.md), [code-map.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/code-map.md) |
| Enemy navigation | working | Enemies chase engage points near the player, hold/facing at melee range, apply soft local spreading, and physically collide with other enemies while using constrained crowd-yield under player pressure; this is the accepted current melee-navigation baseline and no further follow-up slice is planned right now | [enemy-ai-navigation-v1.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/ai/enemy-ai-navigation-v1.md), [enemy-melee-behavior-v1.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/ai/enemy-melee-behavior-v1.md), [enemy-dense-scene-navigation-performance-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/completed/enemy-dense-scene-navigation-performance-slice.md) |
| Enemy death and HP | partial | HP display, damage, and death exist; final verification and feel tuning still pending | [combat.md](d:/Game/DEV/iiWii/iiwii/docs/systems/combat.md) |
| Player attack behavior slice | working | Mouse/world aim, no-fire gating, blocker-aware projectile travel, and demo-scene validation are complete for the current slice scope | [player-attack-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/completed/player-attack-behavior-slice.md) |
| Debug control panel slice | working | `F3` debug menu now exposes projectile debug-line toggles, lightweight runtime stats, enemy navigation/crowd-performance counters, and optional CSV logging to `user://enemy_nav_perf_log.csv` | [debug-control-panel-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/completed/debug-control-panel-slice.md), [enemy-crowd-performance-and-contact-stability-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/completed/enemy-crowd-performance-and-contact-stability-slice.md) |
| Enemy close-range melee behavior slice | working | Engage-point movement, hold/facing, soft spreading, and constrained crowd-yield behavior are implemented and manually validated in the demo scene | [enemy-melee-behavior-v1.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/ai/enemy-melee-behavior-v1.md) |
| Combat feedback and debug behavior slice | deferred | Parked until a new non-navigation gameplay scope is explicitly chosen | [combat-feedback-and-debug-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/stale/combat-feedback-and-debug-behavior-slice.md) |
| Traversal features | partial | Shared dodge/dash mobility and authored low-obstacle vault are now working; crouch, mantle/climb-up, and broader traversal follow-ups remain pending | [traversal-and-verticality.md](d:/Game/DEV/iiWii/iiwii/docs/systems/traversal-and-verticality.md), [player-traversal-and-movement-slice-roadmap.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/roadmaps/player-traversal-and-movement-slice-roadmap.md) |
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
