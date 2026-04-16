# Player Crouch Movement-State Slice

## Status
- `completed`

## Purpose
- Deliver physical hold-to-crouch movement as the next traversal slice after vault.
- Let the player pass under low-clearance world geometry without adding a bespoke authored trigger model for v1.
- Keep crouch separate from dodge/dash, vault, mantle, and high-attack avoidance follow-ups.

## Delivered Scope
1. `Ctrl` now maps to the `crouch` input action.
2. Holding `Ctrl` enters crouch when the player is not in a lock traversal state.
3. Crouch physically lowers the player capsule and visible body.
4. Releasing `Ctrl` only returns to standing when the upper clearance volume between crouched and standing height is free.
5. Crouch movement uses a `0.6` speed multiplier, roughly a 40% slowdown from normal walking.
6. Attacks, dodge/dash, and vault are blocked while crouched.
7. `DemoMain.tscn` includes a low-clearance ceiling fixture for manual validation.

## Runtime Behavior Summary
- Current runtime owner: `godot/scripts/player/player_controller.gd`
- Input: `crouch` on `Ctrl`, hold behavior
- Current tuning:
  - `crouch_speed_multiplier = 0.6`
  - standing collision height is captured from `Player.tscn` at runtime
  - standing collision center is captured from `Player.tscn` at runtime
  - `crouch_collision_height = 0.95`
  - `crouch_collision_center_y = 0.5`
- Stand-up validation queries only the upper clearance volume between crouched height and standing height, so the floor is not part of the stand blocker test.
- If the standing query overlaps blocking world geometry, the player stays crouched after `Ctrl` is released.

## Intentional Non-Goals
- No high-attack avoidance tags in this slice.
- No crouch toggle option yet.
- No dedicated `LowClearanceTrigger` or authored crouch affordance yet.
- No crouch animation/VFX/audio pass.
- No crouch-specific enemy or AI traversal behavior.
- No mantle/climb-up behavior.

## Validation Notes
Manual runtime smoke validation was completed in editor after the stand-up query fix:
1. Hold `Ctrl` and confirm the player visibly lowers.
2. Confirm crouch movement is slower than normal movement.
3. Move under `WorldRoot/TraversalFixtures/LowClearanceCrouchFixture` while crouched.
4. Release `Ctrl` under the low-clearance fixture and confirm the player remains crouched.
5. Move out from under the fixture and confirm the player returns to standing after clearance exists.
6. While crouched, confirm attack, dodge/dash, and vault do not start.

## Follow-Up Candidates
- High/Ground/Neutral attack tag avoidance.
- Optional crouch toggle setting.
- Dedicated low-clearance authoring helpers if physical geometry alone becomes hard to read or tune.
- Crouch animation and feedback polish.
