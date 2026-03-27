# Camera Rotation And Zoom Slice

## Status
- `active`

## Purpose
- Add a Diablo-like gameplay camera with player-controlled rotation and zoom.
- Replace the current bootstrap camera behavior with a stable soft-follow camera.
- Ensure player movement stays camera-relative as the camera rotates.

## Why This Slice Exists
1. The current prototype camera is only a bootstrap scene camera.
2. The next gameplay-facing improvement should increase readability and control feel without reopening enemy-navigation work.
3. Camera rotation changes movement interpretation, so movement-basis handling must be updated as part of the same slice.
4. Cursor/world aiming already depends on the active gameplay camera, so camera behavior must stay explicit and testable.

## Scope
- Gameplay camera framing in `DemoMain`.
- Player-controlled camera rotation.
- Player-controlled zoom in/out within a constrained gameplay-safe range.
- Soft-follow behavior for the gameplay camera.
- Camera-relative player movement that updates correctly with camera rotation.
- Validation that aiming still works under the new camera behavior.

## Out Of Scope
- Cinematic camera work.
- Automatic combat camera modes.
- Large occlusion/visibility systems.
- Controller-first camera design.
- Broader movement/traversal features beyond the camera-relative movement update required by rotation.

## Step Status Board
- Step 1 - Camera behavior contract and controls: `not_started`
- Step 2 - Runtime camera rig support: `not_started`
- Step 3 - Camera-relative movement update: `not_started`
- Step 4 - Aim validation under rotation and zoom: `not_started`
- Step 5 - Slice validation and doc sync: `not_started`

## Step 1 - Camera Behavior Contract And Controls
Status:
- `not_started`

Intent:
- Lock the baseline camera feel before implementation drift starts.

Implementation direction:
1. Use the Diablo-like framing direction from the existing ADRs.
2. Treat soft-follow as the baseline, not fully fixed world framing.
3. Add explicit player-facing controls for:
   - rotate left
   - rotate right
   - zoom in
   - zoom out
4. Keep the allowed zoom range deliberately narrow.

Exit check:
- The target camera behavior is explicit enough that runtime work does not need to guess between fixed, dead-zone, or loose-follow models.

## Step 2 - Runtime Camera Rig Support
Status:
- `not_started`

Intent:
- Turn the current bootstrap camera into a reusable gameplay camera rig.

Implementation direction:
1. Keep camera responsibilities separated in a dedicated rig path.
2. Add follow behavior centered on the player with light smoothing.
3. Add yaw rotation support around the player.
4. Add constrained zoom handling.

Exit check:
- The camera can follow, rotate, and zoom during play without breaking ordinary scene readability.

## Step 3 - Camera-Relative Movement Update
Status:
- `not_started`

Intent:
- Make movement remain intuitive after camera rotation.

Implementation direction:
1. Drive movement direction from the active gameplay camera basis projected onto the XZ plane.
2. Keep movement independent from camera pitch.
3. Ensure facing and locomotion still behave predictably for the current slice.

Exit check:
- After rotating the camera, `W/A/S/D` still map naturally relative to the camera view.

## Step 4 - Aim Validation Under Rotation And Zoom
Status:
- `not_started`

Intent:
- Preserve the existing cursor/world aim model while camera controls are added.

Implementation direction:
1. Recheck cursor pick against ground, enemies, and blockers after camera rotation.
2. Recheck elevated and flat-ground aiming.
3. Verify zoom changes do not create confusing aim failure for normal use.

Exit check:
- Aiming remains predictable enough that the player attack baseline still feels deliberate and reliable.

## Step 5 - Slice Validation And Doc Sync
Status:
- `not_started`

Intent:
- Close the slice cleanly with manual validation and updated runtime-truth docs.

Validation plan:
1. Rotate the camera while moving and confirm movement stays camera-relative.
2. Zoom in and out and confirm the allowed range remains useful and readable.
3. Attack enemies, ground, and blockers after rotating the camera.
4. Validate the camera feel in both ordinary movement and dense enemy situations.
5. Confirm the camera does not feel rigidly fixed or excessively floaty.

Acceptance checks:
1. Camera rotation works in runtime.
2. Zoom in/out works in runtime.
3. Soft-follow framing feels stable and readable.
4. Movement remains intuitive after camera rotation.
5. Cursor/world aiming remains usable after camera changes.
6. The slice does not reopen melee-navigation scope.

## Initial Risks
1. Excessive smoothing could make movement and aiming feel disconnected.
2. Rotation without movement-basis updates would make controls feel wrong immediately.
3. Zoom changes may amplify aim/parallax confusion if the cursor-pick rules are not revalidated.
4. Overly wide zoom bounds could hurt combat readability.

## Next Step
- Implement the camera rig and movement-basis changes together so camera rotation never lands without camera-relative movement support.
