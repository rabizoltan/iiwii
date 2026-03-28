# Camera And Framing
Category: Runtime System
Role: Reference Contract
Last updated: 2026-03-28
Last validated: 2026-03-28

## Purpose
- Define the intended gameplay camera behavior for the current vertical slice.
- Keep camera rules explicit because camera framing affects movement readability, aiming, and combat feel.

## Current Runtime State
- `res://scenes/camera/GameplayCameraRig.tscn` now owns the reusable gameplay camera rig for the vertical slice, and `DemoMain.tscn` instances it.
- The current runtime supports middle-mouse drag yaw rotation, constrained zoom, and soft-follow framing around the player.
- Player movement now uses the active camera basis so controls stay camera-relative as the camera rotates.
- Zoom now moves toward a target distance smoothly instead of stepping immediately to each wheel increment.
- Manual in-engine validation in `DemoMain.tscn` confirmed the current camera baseline is accepted for the milestone.

## Target Style For The Next Slice
- Use a Diablo-like gameplay camera.
- The camera should remain top-down / isometric-ish in overall presentation.
- The camera should not behave like a free-look action camera or a detached RTS camera.
- The camera should support:
  - player-controlled rotation
  - zoom in
  - zoom out
  - camera-relative movement that updates correctly as the camera rotates

## Follow Behavior
- Use a soft-follow camera rather than a completely fixed world camera.
- The player should stay near the center of gameplay framing so combat and aiming remain readable.
- Follow smoothing should be light and stable:
  - enough to avoid harsh jitter
  - not so loose that the player feels disconnected from the camera
- Do not introduce a large dead-zone, edge-push camera, or heavy lag for this slice.

Reason:
- A Diablo-like camera is primarily a stable readability camera.
- Small smoothing is useful, but the player should still feel anchored in the center of the action.

## Rotation Rules
- Rotation is allowed around the vertical axis.
- Current baseline controls use middle-mouse drag for rotation.
- Rotation should be deliberately player-controlled, not constantly auto-rotating during ordinary movement or aim.
- Rotation should preserve readability of the current combat space and should not break cursor/world aiming.
- Movement input must remain camera-relative after rotation:
  - `W` should move toward the camera's forward-on-ground direction
  - `S` should move opposite that direction
  - `A` and `D` should move along the camera's ground-projected left/right basis

## Zoom Rules
- Zoom in and zoom out are part of the slice scope.
- Current baseline controls use mouse wheel plus keyboard zoom actions.
- Zoom should stay within a constrained gameplay-safe range.
- Zoom should preserve:
  - aim readability
  - player/enemy silhouette readability
  - awareness of nearby crowd pressure
- Zoom should not change the game into an over-the-shoulder view or an excessively distant strategy view.
- Zoom should feel smooth and continuous rather than visually jerky.

## Aiming And Combat Interaction
- Cursor/world aiming remains the baseline attack model.
- Camera rotation and zoom must not invalidate the existing cursor-pick rules from [combat.md](d:/Game/DEV/iiWii/iiwii/docs/systems/combat.md) and [ADR-016-space-model-continuous-world-navmesh-no-tile-diagonals.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-016-space-model-continuous-world-navmesh-no-tile-diagonals.md).
- Any camera changes must preserve predictable cursor-to-world aim resolution.
- Top-down parallax remains acceptable, but the resulting aim behavior must stay documented and testable.

## Reuse In New Maps
- Instance `res://scenes/camera/GameplayCameraRig.tscn` into the playable map scene.
- Set the instance `target_path` to the player node that should be followed.
- Keep that instance as the active gameplay `Camera3D` for the scene.
- Override tuning on the scene instance only when a specific map needs different framing or zoom bounds.
- Player movement will stay camera-relative as long as the scene has this active gameplay camera.

## Current Baseline Setup
- Reusable camera scene: `res://scenes/camera/GameplayCameraRig.tscn`
- Runtime behavior script: `res://scripts/main/gameplay_camera_rig.gd`
- Current validation example: `res://scenes/main/DemoMain.tscn`
- Current default interaction model:
  - hold middle mouse button and drag to rotate
  - use mouse wheel to zoom
  - optional keyboard zoom actions remain available from the project input map
## Responsibilities
- Reusable camera scene and rig script own framing, follow smoothing, rotation, and zoom behavior.
- Map scenes own which camera instance is active and which player target path it follows.
- Player movement code owns conversion from input intent to world movement using the active camera basis.
- Combat and aiming code continue to own cursor/world target resolution and projectile dispatch.

## Non-Goals For This Slice
- No cinematic camera system.
- No room-by-room authored camera rails.
- No full occlusion-management system.
- No controller-first twin-stick camera design.
- No automatic combat camera behavior that changes aggressively by context.

## Acceptance Criteria
1. The player can rotate the gameplay camera during play.
2. The player can zoom in and out within a constrained useful range.
3. Movement remains intuitive after camera rotation because it uses the active camera basis.
4. The camera follows the player with stable Diablo-like framing rather than rigid world-fixed framing.
5. Cursor/world aiming still works predictably after camera rotation and zoom changes.
6. The camera does not introduce distracting jitter, heavy lag, or large framing drift during ordinary movement and combat.
