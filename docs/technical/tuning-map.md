# Tuning Map
Category: Runtime Architecture
Role: Runtime Truth
Last updated: 2026-03-18
Last validated: pending

## Purpose
- Track where runtime tuning and config values actually live today.
- Make tuning ownership discoverable without reading every gameplay script.
- Clarify which values are code-owned now versus only planned as future shared config resources.

## Current State
- The current vertical-slice baseline keeps most active tuning values in exported script variables under `godot/scripts/`.
- There is no shared gameplay tuning resource or dedicated `godot/resources/` tuning layer yet.
- Planned config-oriented docs such as [enemy-ai-config-v1.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/ai/enemy-ai-config-v1.md) describe target structure, not current runtime ownership.

## Ownership Rules
- If a gameplay value is actively used at runtime, this map should point to the owning file.
- If a value is only planned for a future data/config layer, do not present it here as current runtime truth.
- When shared resources or data files are introduced later, update this map before treating them as canonical tuning owners.

## Current Runtime Tuning Owners

| Area | Current owner | Current tuning surface | Notes | Related docs |
| --- | --- | --- | --- | --- |
| Player movement | `godot/scripts/player/player_controller.gd` | `move_speed`, `turn_speed` | Current baseline movement tuning is script-owned and minimal. | [movement-spec.md](d:/Game/DEV/iiWii/iiwii/docs/systems/movement-spec.md), [tuning-and-stats.md](d:/Game/DEV/iiWii/iiwii/docs/systems/tuning-and-stats.md) |
| Player attack cadence and targeting | `godot/scripts/player/player_controller.gd` | `attack_cooldown`, `aim_collision_mask`, `aim_ray_length` | Current attack cadence and aim query parameters are script-owned. | [combat.md](d:/Game/DEV/iiWii/iiwii/docs/systems/combat.md) |
| Projectile runtime | `godot/scripts/projectiles/projectile.gd` | `speed`, `damage`, `hit_collision_mask` | Projectile speed and damage remain code-owned exports in the current slice. | [combat.md](d:/Game/DEV/iiWii/iiwii/docs/systems/combat.md) |
| Enemy locomotion and melee behavior | `godot/scripts/enemy/enemy_controller.gd` | movement speed, engage distances, close-adjust values, crowd-pressure values, goal-selection values, stuck-fallback values | The current melee baseline keeps almost all enemy behavior tuning in one script-owned surface. | [enemy-movement-runtime-ownership.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/ai/enemy-movement-runtime-ownership.md), [enemy-ai-config-v1.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/ai/enemy-ai-config-v1.md), [tuning-and-stats.md](d:/Game/DEV/iiWii/iiwii/docs/systems/tuning-and-stats.md) |
| Enemy debug and profiling toggles | `godot/scripts/enemy/enemy_controller.gd`, `godot/scripts/debug/debug_overlay.gd` | debug enable flags, profiler enable state, projectile debug line toggle | Debug visualization and profiling control are split between enemy runtime and debug UI shell. | [debug-control-panel-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/completed/debug-control-panel-slice.md), [code-map.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/code-map.md) |

## Planned But Not Current Owners
- Shared enemy AI config resources are still future-facing; see [enemy-ai-config-v1.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/ai/enemy-ai-config-v1.md).
- Broader movement/combat tuning consolidation is still future-facing; see [tuning-and-stats.md](d:/Game/DEV/iiWii/iiwii/docs/systems/tuning-and-stats.md).
- Save/progression config and inventory data layers are still future-facing and should not be treated as current runtime tuning owners.

## Update Rules
- Update this map when a new runtime tuning owner appears.
- Update this map when a tuning surface moves from script exports into shared resources or config files.
- Update [code-map.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/code-map.md) alongside this file when a new runtime config file or resource becomes active.
- Update [feature-matrix.md](d:/Game/DEV/iiWii/iiwii/docs/technical/feature-matrix.md) if the tuning move changes feature status or milestone readiness.

## Next Expected Evolution
- Add a dedicated row when gameplay tuning first moves into `godot/resources/` or another shared data layer.
- Split enemy behavior tuning into smaller owners once the repo stops using `enemy_controller.gd` as the primary aggregate tuning surface.
