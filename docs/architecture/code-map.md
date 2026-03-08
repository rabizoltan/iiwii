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
- The next planned implementation target is the player attack behavior slice.
- The next planned follow-up after that is the melee close-range enemy behavior slice.

## Entry Format
Use one row per important runtime file or scene once implementation starts.

| Path | Type | Owns | Referenced By | Primary Docs |
| --- | --- | --- | --- | --- |
| `godot/project.godot` | project config | Godot project bootstrap, main scene entry, initial input actions, and debug-toggle binding | Godot editor runtime | [first-playable-vertical-slice-execution-plan.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/first-playable-vertical-slice-execution-plan.md) |
| `godot/scenes/main/DemoMain.tscn` | scene | Initial playable world scaffold: floor, obstacles, camera, spawn anchors, nav region, and actor placement | `godot/project.godot` | [first-playable-vertical-slice-execution-plan.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/first-playable-vertical-slice-execution-plan.md), [movement-spec.md](d:/Game/DEV/iiWii/iiwii/docs/systems/movement-spec.md), [enemy-ai-navigation-v1.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/ai/enemy-ai-navigation-v1.md) |
| `godot/scenes/player/Player.tscn` | scene | Player actor root, collision, visible body, and projectile spawn anchor | `godot/scenes/main/DemoMain.tscn` | [movement-spec.md](d:/Game/DEV/iiWii/iiwii/docs/systems/movement-spec.md) |
| `godot/scripts/player/player_controller.gd` | script | XZ player movement, facing, floor-safe body motion, basic projectile attack spawning, and enemy debug toggle input handling | `godot/scenes/player/Player.tscn` | [movement-spec.md](d:/Game/DEV/iiWii/iiwii/docs/systems/movement-spec.md), [combat.md](d:/Game/DEV/iiWii/iiwii/docs/systems/combat.md) |
| `godot/scenes/enemy/EnemyBasic.tscn` | scene | Enemy actor root, collision, visible body, and nav agent setup | `godot/scenes/main/DemoMain.tscn` | [enemy-ai-navigation-v1.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/ai/enemy-ai-navigation-v1.md) |
| `godot/scripts/enemy/enemy_controller.gd` | script | Basic enemy chase toward player via `NavigationAgent3D`, stop-distance hold, stuck recovery, HP, death, and overhead enemy debug/HP label control | `godot/scenes/enemy/EnemyBasic.tscn` | [enemy-ai-navigation-v1.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/ai/enemy-ai-navigation-v1.md), [combat.md](d:/Game/DEV/iiWii/iiwii/docs/systems/combat.md), [ADR-018-enemy-ai-nav-v1-approach.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-018-enemy-ai-nav-v1-approach.md) |
| `godot/scenes/projectiles/Projectile.tscn` | scene | Minimal projectile for the first playable combat slice | `godot/scripts/player/player_controller.gd` | [combat.md](d:/Game/DEV/iiWii/iiwii/docs/systems/combat.md) |
| `godot/scripts/projectiles/projectile.gd` | script | Projectile travel, lifetime, collision hit, and damage dispatch | `godot/scenes/projectiles/Projectile.tscn` | [combat.md](d:/Game/DEV/iiWii/iiwii/docs/systems/combat.md) |

## Next Expected Entries
When the next steps start, add entries for:
- any shared tuning or config resource
- combat feedback or hit VFX files
