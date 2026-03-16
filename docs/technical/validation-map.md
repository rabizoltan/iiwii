# Validation Map
Category: Verification
Role: Verification Guide
Last updated: 2026-03-16
Last validated: pending

## Purpose
- Track how current behaviors are validated in this repo.
- Make manual validation entry points discoverable without reading every slice plan.
- Clarify which fixtures, scenes, toggles, and documents are used to verify current gameplay work.

## Current Validation Model
- The current vertical-slice repo relies primarily on manual in-engine validation in `godot/scenes/main/DemoMain.tscn`.
- Workplans and verification docs define scenario-specific pass conditions.
- Debug tooling in the demo scene supports validation, but there is no separate automated gameplay test suite yet.

## Primary Validation Entry Points

| Validation area | Primary scene / surface | Current method | Main verification docs |
| --- | --- | --- | --- |
| Player attack baseline | `godot/scenes/main/DemoMain.tscn` | manual demo-scene checks against enemy, ground, obstacle, and elevated targets | [player-attack-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/player-attack-behavior-slice.md), [combat.md](d:/Game/DEV/iiWii/iiwii/docs/systems/combat.md) |
| Debug control panel | `godot/scenes/main/DemoMain.tscn`, `F3` menu | manual toggle checks for enemy status, nav path, and projectile debug lines | [debug-control-panel-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/debug-control-panel-slice.md) |
| Enemy melee close-range behavior | `godot/scenes/main/DemoMain.tscn` crowd fixtures | manual observation of hold stability, spreading, player-moves-away follow behavior, dense crowd pressure, and scene-level collision/traversal fit on ramps or slopes | [enemy-ai-testplan-v1.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/ai/enemy-ai-testplan-v1.md), [enemy-close-range-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/enemy-close-range-behavior-slice.md), [enemy-melee-behavior-v1.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/ai/enemy-melee-behavior-v1.md) |
| Runtime observability and profiling | `godot/scenes/main/DemoMain.tscn`, debug overlay, debug logs under `user://debug` | manual visual checks plus lightweight file/log inspection | [debug-control-panel-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/debug-control-panel-slice.md), [code-map.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/code-map.md) |

## Current Validation Fixtures
- `DemoMain.tscn` is the main current validation scene.
- The demo scene includes:
  - player start and movement space
  - stationary target dummy
  - reachable elevated shooting platform
  - navmesh and obstacle layout
  - denser multi-line enemy crowd fixture
  - shared debug overlay and debug-world anchors

## Shared Validation Aids
- When debugging enemy traversal, verify the enemy collision capsule, body mesh fit, and NavigationAgent3D dimensions before assuming a navmesh or controller bug.

- `F3` debug menu for central toggle-based runtime visibility
- enemy status labels
- enemy nav path visualization
- projectile debug lines
- enemy profiling readout and periodic profiling log output

## Validation Ownership Rules
- If a workplan defines the current execution gate, keep its concrete pass steps there.
- If a behavior already has a stable reusable verification pattern, link it here so future sessions can find it quickly.
- If a validation flow depends on a debug toggle, fixture, or dedicated scene setup, record that dependency here.
- If automated tests are added later, this map should point to them but not replace their detailed docs.

## Current Gaps
- There is no automated gameplay regression suite yet.
- There is no dedicated standalone test scene matrix beyond the current demo-scene fixtures.
- Some future-facing validation docs describe broader target fixture sets that do not fully exist in the repo yet.

## Update Rules
- Update this file when a new reusable validation fixture or scene becomes part of normal workflow.
- Update this file when a behavior slice adds a stable manual validation recipe worth reusing.
- Update [code-map.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/code-map.md) when validation depends on a new runtime-owned debug surface.
- Update [feature-matrix.md](d:/Game/DEV/iiWii/iiwii/docs/technical/feature-matrix.md) if validation changes feature readiness or status.


