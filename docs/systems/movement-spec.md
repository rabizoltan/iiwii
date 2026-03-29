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
- In this file, baseline movement and shared mobility describe current runtime truth; vault and crouch sections describe the intended contract for pending traversal slices and should not be read as already-implemented runtime behavior.
- For traversal semantics and the vault-vs-mantle boundary, see [traversal-and-verticality.md](d:/Game/DEV/iiWii/iiwii/docs/systems/traversal-and-verticality.md).

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
  - a nearby authored vault traversal node such as `VaultTrigger` or `VaultLink`
  - valid approach side or alignment for that traversal node
  - active movement intent toward the obstacle when the vault request happens
  - valid landing position on the far side against world geometry
- Explicit non-goal for v1:
  - getting onto a meaningfully higher platform is **mantle / climb-up**, not vault

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
- The mobility start frame should apply movement immediately so dash handoff stays smooth while movement input is already held.
- Collision behavior:
  - mobility grants a short tunable `ghosted` or `unhindered` window against enemy bodies so dense contact can be escaped explicitly
  - this window is driven by mobility state, not by baseline locomotion pushing enemies away
- Future invulnerability, blink, and authored trail or end effects remain follow-up work rather than current runtime truth.

## Vault Behavior (Reference Contract, Not Yet Runtime Truth)
- Vault is a short contextual traversal move over a low authored obstacle.
- Vault should start from one side of the obstacle and land on the far side in one committed motion.
- Vault should return the player to roughly the same floor level.
- Vault should be driven by obstacle-authored traversal data rather than raw geometry guessing.
- Recommended obstacle-side data owner:
  - a dedicated traversal node or component such as `VaultTrigger` or `TraversalMarker`
- That traversal data should define at least:
  - traversal type
  - valid approach side or entry region
  - start anchor or alignment
  - exit landing anchor
  - optional traversal duration or local tuning overrides
- Candidate selection should prefer valid authored vault nodes in front of the player, then choose the nearest valid candidate among them.
- A forgiving front-facing cone of roughly `45` degrees is the intended starting point for v1 candidate filtering.
- Vault directionality should be authored per obstacle; one-way should be the default expectation, while bidirectional use is allowed when explicitly authored.
- Vault should activate only from a short readable distance near the authored entry region, not from long-range.
- Vault should lock normal locomotion, mobility, and attacks during travel.
- Vault should use a short fixed-duration committed move with a small readable arc.
- The default arc should derive from obstacle height plus a small clearance margin, with sane clamp limits.
- Enemy bodies should not block the vault once it starts, but world collision and landing validity still matter.
- Nearby enemy bodies should not hard-block vault start by themselves; temporary enemy ghosting during vault travel is acceptable for readability and reliability, and any end overlap should resolve with gentle separation rather than strong knockback.
- Platform climb-up, ledge grab, and mantle behavior remain out of scope for the first vault slice.

## Input Mapping Defaults
Default input mapping target:
- `W/A/S/D` movement
- `Ctrl` crouch
- `Space` vault
- `Shift` dodge
- left mouse button attack

## Non-Goals (Current Prototype)
- No jump state
- No slope-specific locomotion model
- No stamina gating
- No blink or teleport mobility in the current slice
- No mantle or climb-up behavior in the first vault slice

## Player vs Enemy Collision Direction
- Normal locomotion should not push enemies away as a baseline movement rule.
- Enemy pressure should come from body blocking and combat threat, not a continuous shove loop.
- Enemy displacement caused by the player should be an authored combat effect, not a default locomotion side effect.
