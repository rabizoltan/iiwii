# Code Map

## Purpose
- Track the actual runtime file relationships once code exists.
- Give humans and LLMs one place to see which files own behavior and which files depend on them.

## Usage Rules
- Update this file when a new runtime file is created.
- Update this file when ownership or important references change.
- Keep entries factual and short.
- Do not duplicate full design logic here; point back to source-of-truth docs.

## Current State
- Initial Godot project bootstrap files now exist.
- Player movement, enemy chase, and first-pass combat files now exist.
- The melee close-range enemy behavior slice is implemented for the current milestone.
- The next planned follow-up is the combat feedback and debug behavior slice, which remains blocked pending scope decisions.

## Entry Format
Use one row per important runtime file or scene once implementation starts.

| Path | Type | Owns | Referenced By | Primary Docs |
| --- | --- | --- | --- | --- |
| `godot/project.godot` | project config | Godot project bootstrap and main scene entry | Godot editor runtime | [first-playable-vertical-slice-execution-plan.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/first-playable-vertical-slice-execution-plan.md) |
| `godot/scenes/main/DemoMain.tscn` | scene | Initial playable world scaffold plus the current melee close-range validation layout: floor, obstacles, camera, spawn anchors, nav region, actor placement, a stationary target dummy, a reachable elevated shooting test platform, a denser multi-line enemy crowd fixture, and shared debug overlay/world anchors | `godot/project.godot` | [first-playable-vertical-slice-execution-plan.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/first-playable-vertical-slice-execution-plan.md), [movement-spec.md](d:/Game/DEV/iiWii/iiwii/docs/systems/movement-spec.md), [enemy-ai-navigation-v1.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/ai/enemy-ai-navigation-v1.md), [enemy-close-range-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/enemy-close-range-behavior-slice.md), [player-attack-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/player-attack-behavior-slice.md), [debug-control-panel-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/debug-control-panel-slice.md) |
| `godot/scripts/main/demo_main_controller.gd` | script | Global demo-scene input handling for shared runtime debug menu controls | `godot/scenes/main/DemoMain.tscn` | [debug-control-panel-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/debug-control-panel-slice.md) |
| `godot/scenes/player/Player.tscn` | scene | Player actor root, collision, visible body, and chest-height projectile spawn anchor | `godot/scenes/main/DemoMain.tscn` | [movement-spec.md](d:/Game/DEV/iiWii/iiwii/docs/systems/movement-spec.md), [combat.md](d:/Game/DEV/iiWii/iiwii/docs/systems/combat.md) |
| `godot/scripts/player/player_controller.gd` | script | XZ player movement, movement-facing rotation, mouse/world aim target resolution, single-shot cooldown gating, and projectile spawning | `godot/scenes/player/Player.tscn` | [movement-spec.md](d:/Game/DEV/iiWii/iiwii/docs/systems/movement-spec.md), [combat.md](d:/Game/DEV/iiWii/iiwii/docs/systems/combat.md), [ADR-007-input-and-controls.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-007-input-and-controls.md), [ADR-016-space-model-continuous-world-navmesh-no-tile-diagonals.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-016-space-model-continuous-world-navmesh-no-tile-diagonals.md) |
| `godot/scenes/enemy/EnemyBasic.tscn` | scene | Enemy actor root, collision contract for world/player/enemy interaction, visible body, and nav agent setup | `godot/scenes/main/DemoMain.tscn` | [enemy-ai-navigation-v1.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/ai/enemy-ai-navigation-v1.md), [enemy-close-range-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/enemy-close-range-behavior-slice.md) |
| `godot/scripts/enemy/enemy_controller.gd` | script | Melee enemy engage-goal selection, hold/facing behavior, soft local spreading, constrained crowd-yield response under player pressure, minimal stuck fallback, HP/death handling, overhead enemy status labels, nav/goal/yield debug rendering and logging, plus aggregated profiling hooks and light far-enemy nav refresh caching | `godot/scenes/enemy/EnemyBasic.tscn` | [enemy-ai-navigation-v1.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/ai/enemy-ai-navigation-v1.md), [enemy-close-range-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/enemy-close-range-behavior-slice.md), [combat.md](d:/Game/DEV/iiWii/iiwii/docs/systems/combat.md), [ADR-018-enemy-ai-nav-v1-approach.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-018-enemy-ai-nav-v1-approach.md), [debug-control-panel-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/debug-control-panel-slice.md) |
| `godot/scenes/projectiles/Projectile.tscn` | scene | Baseline non-piercing projectile used by the player attack behavior slice | `godot/scripts/player/player_controller.gd` | [combat.md](d:/Game/DEV/iiWii/iiwii/docs/systems/combat.md) |
| `godot/scripts/projectiles/projectile.gd` | script | 3D projectile travel toward a resolved aim point, blocker-aware segment hit resolution, non-piercing damage dispatch, and optional projectile debug line emission | `godot/scenes/projectiles/Projectile.tscn` | [combat.md](d:/Game/DEV/iiWii/iiwii/docs/systems/combat.md), [ADR-016-space-model-continuous-world-navmesh-no-tile-diagonals.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-016-space-model-continuous-world-navmesh-no-tile-diagonals.md), [debug-control-panel-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/debug-control-panel-slice.md) |
| `godot/scenes/debug/DebugOverlay.tscn` | scene | In-game debug menu shell opened by `F3` with shared debug toggle controls, lightweight runtime stats, and an enemy profiling readout | `godot/scenes/main/DemoMain.tscn` | [debug-control-panel-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/debug-control-panel-slice.md) |
| `godot/scripts/debug/debug_overlay.gd` | script | Shared runtime debug state, menu visibility state, projectile debug line spawning, lightweight runtime stats refresh, and aggregated enemy profiling display/logging | `godot/scenes/debug/DebugOverlay.tscn` | [debug-control-panel-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/debug-control-panel-slice.md) |
| `godot/scenes/debug/DebugLine3D.tscn` | scene | Short-lived 3D debug line used for projectile flight visualization | `godot/scripts/debug/debug_overlay.gd` | [debug-control-panel-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/debug-control-panel-slice.md) |
| `godot/scripts/debug/debug_line_3d.gd` | script | Builds and auto-expires simple 3D line meshes for runtime debug visualization | `godot/scenes/debug/DebugLine3D.tscn` | [debug-control-panel-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/debug-control-panel-slice.md) |

## Next Expected Entries
When the next steps start, add entries for:
- any shared tuning or config resource
- combat feedback or hit VFX files
