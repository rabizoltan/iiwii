# Movement Spec
Category: Runtime System
Role: Reference Contract
Last updated: 2026-03-30
Last validated: manual editor validation after crouch stand-up query fix

This document defines the current runtime player locomotion and shared traversal behavior for the vertical slice.

## Scope
- This document reflects current runtime truth for baseline movement, physical hold-to-crouch behavior, shared dodge/dash mobility, and the authored vault traversal slice.
- The current runtime owner is `godot/scripts/player/player_controller.gd`.
- Crouch is now implemented as a physical low-profile state with slower movement and stand-up clearance validation.
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
3. Else update hold-to-crouch state and stand-up clearance.
4. Then handle dodge input first, then vault input.
5. Then handle attacks if not crouched.
6. Then handle facing update and movement.

This ordering means vault and dodge are traversal-lock states that suppress regular movement and attacks for that tick, while crouch is a locomotion state that suppresses attack, dodge, and vault starts.

## Transitions

### Standing <-> Crouching
- Trigger: `crouch` action held (`Ctrl` by default).
- Crouch is hold-driven in the current runtime; toggle crouch is not implemented yet.
- Entering crouch lowers the player collision capsule and visible body.
- Releasing `Ctrl` attempts to stand.
- If the upper clearance volume between crouched and standing height is blocked, the player remains crouched until standing clearance exists.
- Crouch reduces normal movement speed through `crouch_speed_multiplier = 0.6`.
- While crouched, attacks, dodge/dash, and vault starts are blocked.

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
  - player is on floor
  - a nearby authored `VaultTrigger` candidate is registered
  - the candidate is on a valid authored side
  - the player has active movement intent toward the obstacle when the request happens
  - movement intent passes the configured forward-alignment gate
  - the landing resolves to valid world floor with clearance on roughly the same floor level
- Explicit non-goal for v1:
  - getting onto a meaningfully higher platform is **mantle / climb-up**, not vault

### Dodging/Vaulting -> Standing
- When timer expires, runtime returns to normal locomotion.
- Crouch exits to standing only after standing clearance exists.

## Movement Formulas

### Input Space
- Movement basis uses the active gameplay camera forward and right projected on XZ.
- Camera pitch must not directly tilt movement into the ground or air.
- If the camera rotates around the player, movement intent rotates with it.

### Target Speed
- Standing speed: `move_speed`
- Crouching speed: `move_speed * crouch_speed_multiplier`

### Horizontal Velocity
- `target_velocity = move_dir * active_speed`
- `active_speed` is `move_speed` while standing and `move_speed * crouch_speed_multiplier` while crouched.
- Player controller writes X/Z velocity directly from movement intent during normal locomotion.

### Vertical
- On floor: `velocity.y = 0`
- In air: `velocity.y -= gravity * delta`

## Crouch Behavior
- Crouch is a physical low-profile movement state.
- Crouch lowers the active player capsule from standing dimensions to crouch dimensions.
- Current crouch is controlled by holding `Ctrl`.
- The player remains crouched after releasing `Ctrl` if the upper clearance volume between crouched and standing height is blocked.
- Low-clearance traversal is validated by physics shape clearance, not by a dedicated authored trigger in v1.
- Crouch currently blocks attacks, dodge/dash, and vault starts.
- Avoiding attacks tagged `High` remains a later combat-rule follow-up.

## Dodge Behavior
- The current implementation uses one shared mobility foundation that can be tuned into either a short `dodge` profile or a longer `dash` profile.
- Travel duration is driven by profile duration exports.
- Travel displacement is driven by profile distance exports.
- The mobility start frame applies movement immediately so dash handoff stays smooth while movement input is already held.
- Collision behavior:
  - mobility grants a short tunable `ghosted` or `unhindered` window against enemy bodies so dense contact can be escaped explicitly
  - this window is driven by mobility state, not by baseline locomotion pushing enemies away
- Future invulnerability, blink, and authored trail or end effects remain follow-up work rather than current runtime truth.

## Vault Behavior
- Vault is a short contextual traversal move over a low authored obstacle.
- Vault starts from one side of the obstacle and lands on the far side in one committed motion.
- Vault returns the player to roughly the same floor level.
- Vault is driven by obstacle-authored traversal data rather than raw geometry guessing.
- Current obstacle-side data owner:
  - `VaultTrigger` with explicit anchor references
- Current authored anchor set:
  - `EntryFaceAnchor`
  - `ExitFaceAnchor`
  - `EntryLandingAnchor`
  - `ExitLandingAnchor`
- Current trigger-side runtime choices:
  - directionality (`ENTRY_TO_EXIT`, `EXIT_TO_ENTRY`, `BIDIRECTIONAL`)
  - traversal model (`FIXED_ENDPOINT`, `STRIP_OFFSET`)
  - optional duration override and landing/clearance tuning
- Candidate selection prefers the lowest-score valid registered trigger.
- Current default forward cone is driven by `vault_facing_angle_degrees = 65`.
- Current default activation distance is driven by `vault_activation_distance = 1.2`.
- Vault directionality is authored per obstacle.
- `STRIP_OFFSET` is available for long straight obstacles so landing preserves along-obstacle offset instead of snapping toward one fixed midpoint.
- Vault locks normal locomotion, mobility, and attacks during travel.
- Vault uses a short fixed-duration committed move with a readable arc.
- The default arc derives from trigger `obstacle_height + arc_clearance`, then clamps through player exports `vault_arc_min_height` and `vault_arc_max_height`.
- Vault travel is applied by directly setting position along the authored path rather than using `move_and_slide()` during the traversal motion.
- Enemy bodies do not block the vault once it starts.
- Nearby enemy bodies do not hard-block vault start by themselves; temporary enemy ghosting during vault travel is used for readability and reliability, and any end overlap resolves with gentle separation rather than strong knockback.
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
- Dodge/dash and vault are the explicit player-controlled escape/traversal cases that may temporarily ghost enemy collision.
