# Movement Spec
Category: Runtime System
Role: Reference Contract
Last updated: 2026-03-29
Last validated: pending

This document defines the intended runtime player locomotion and current first-pass mobility behavior for the vertical slice.

## Scope
- This document now reflects current runtime truth for baseline movement and the first shared mobility foundation.
- The current runtime owner is `godot/scripts/player/player_controller.gd`.
- Vault and crouch remain reference-contract behavior until their implementation slices land.

## State Machine

### States
- `STANDING`
- `CROUCHING`
- `VAULTING`
- `DODGING`

### Priority Rules Per Physics Tick
1. If state is `VAULTING`, process vault and return early.
2. Else if state is `DODGING`, process dodge and return early.
3. Else handle dodge input first, then vault input.
4. Then handle attacks.
5. Then crouch state update, facing update, and movement.

This ordering means vault and dodge are traversal-lock states that suppress regular movement and attacks for that tick.

## Transitions

### Standing <-> Crouching
- Enter crouch while `crouch` action is held.
- Return to standing when crouch is released.
- Entering crouch updates capsule height, collision Y offset, and mesh Y-scale.

### Any Non-Lock State -> Dodging
- Trigger: `dodge` action just pressed.
- Current implementation uses one shared mobility runtime with a tunable `mobility_profile` that can behave as either a short `dodge` or a longer `dash`.
- Blocked when:
  - `dodge_cooldown_remaining > 0`
  - current state is `VAULTING`
- Direction priority:
  - current movement direction
  - last movement direction
  - world forward fallback

### Any Non-Lock State -> Vaulting
- Trigger: `vault` action just pressed.
- Requirements:
  - overlapping `Vaultable` trigger
  - movement input magnitude >= threshold
  - obstacle raycast ahead on world-solid layer
  - obstacle height must be inside `[vault_min_height, vault_max_height]`

### Dodging/Vaulting -> Standing or Crouching
- When timer expires:
  - if crouch is held, end in `CROUCHING`
  - else end in `STANDING`

## Movement Formulas

### Input Space
- If `camera_relative_movement = true`:
  - movement basis uses the active gameplay camera forward and right projected on XZ.
  - camera pitch must not directly tilt movement into the ground or air.
  - if the camera rotates around the player, movement intent rotates with it.
- Else:
  - movement basis uses player local forward and right projected on XZ.

### Target Speed
- Standing speed: `move_speed`
- Crouch speed:
  - `crouch_speed` if `crouch_speed > 0`
  - otherwise `move_speed * crouch_speed_mult`

### Horizontal Velocity Blend
- `target_velocity = move_dir * target_speed`
- `rate = acceleration` while input is active, else `deceleration`
- `response_t = clamp(rate * delta, 0, 1)`
- `horizontal_velocity = lerp(horizontal_velocity, target_velocity, response_t)`

### Vertical
- On floor: `velocity.y = 0`
- In air: `velocity.y -= gravity * delta`

## Dodge Behavior
- The current implementation uses one shared mobility foundation that can be tuned into either a short `dodge` profile or a longer `dash` profile.
- Travel duration is driven by profile duration exports.
- Travel displacement is driven by profile distance exports.
- Position is interpolated from start to end over normalized travel progress.
- Collision behavior:
  - mobility grants a short tunable `ghosted` or `unhindered` window against enemy bodies so dense contact can be escaped explicitly
  - this window is driven by mobility state, not by baseline locomotion pushing enemies away
- Future invulnerability, blink, and authored trail or end effects remain follow-up work rather than current runtime truth.

## Vault Behavior
- Vault duration: `vault_duration`
- Distance:
  - computed from overlapping vault trigger shape projection + `vault_clearance`
  - clamped to `[vault_min_distance, vault_max_distance]`
  - fallback to `vault_default_distance` if no valid trigger shape data
- Position is interpolated from start to end over normalized vault progress.

## Input Mapping Defaults
Default input mapping target:
- `W/A/S/D` movement
- `Ctrl` crouch
- `Space` vault
- `Shift` dodge

## Non-Goals (Current Prototype)
- No jump state
- No slope-specific locomotion model
- No stamina gating
- No blink or teleport mobility in the current slice

## Player vs Enemy Collision Direction
- Normal locomotion should not push enemies away as a baseline movement rule.
- Enemy pressure should come from body blocking and combat threat, not a continuous shove loop.
- Enemy displacement caused by the player should be an authored combat effect, not a default locomotion side effect.
