# Movement Spec
Category: Runtime System
Role: Reference Contract
Last updated: 2026-03-16
Last validated: pending

This document defines the intended runtime player locomotion/traversal behavior for the vertical slice.

## Scope
- This is a behavior specification, not a claim about files currently present in this repository.
- Concrete scene, script, and tuning asset paths should be added only after the gameplay project structure exists here.

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

This ordering means vault/dodge are traversal-lock states that suppress regular movement and attacks for that tick.

## Transitions

### Standing <-> Crouching
- Enter crouch while `crouch` action is held.
- Return to standing when crouch is released.
- Entering crouch updates capsule height, collision Y offset, and mesh Y-scale.

### Any Non-Lock State -> Dodging
- Trigger: `dodge` action just pressed.
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
  - movement basis uses camera forward/right projected on XZ.
- Else:
  - movement basis uses player local forward/right projected on XZ.

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
- Dodge duration: `dodge_duration`
- Dodge displacement:
  - if `dodge_speed > 0`: `dodge_speed * dodge_duration`
  - else: `dodge_distance`
- Position is interpolated from start to end over normalized dodge progress.
- I-frame window:
  - invulnerable when progress in `[dodge_iframes_start, dodge_iframes_end]`
- Collision behavior:
  - dodge should also grant a short `ghosted` or `unhindered` window against enemy bodies so dense contact can be escaped explicitly
  - this window should be driven by dodge state, not by baseline locomotion pushing enemies away

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

## Player vs Enemy Collision Direction
- Normal locomotion should not push enemies away as a baseline movement rule.
- Enemy pressure should come from body blocking and combat threat, not a continuous shove loop.
- Enemy displacement caused by the player should be an authored combat effect, not a default locomotion side effect.
