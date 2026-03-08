# Traversal (Jump/Vault, Crouch) + Verticality

## Goals
- Provide Diablo-like, timing-based traversal (no precision platforming).
- Support flee obstacles (jump/crouch prompts).
- Support multi-level play (ground vs tower/wall) with LOS-based combat.

## Non-goals (for now)
- Physics-driven platforming (ledge grabs, variable jump height, airborne steering precision).
- Freeform vertical movement outside connectors (no "jump anywhere to any height").

## Player traversal states
### Standing
Default state. Full movement + standard hit profile.

### Crouching
- Enter/exit via input (or forced by "low clearance zones").
- Movement speed reduced (tunable).
- **Avoidance rule:** dodges only attacks/hitboxes tagged **High**.

### Vaulting / Jumping
Short-duration traversal state.
- Triggered by input + either:
  - entering a vault obstacle trigger, OR
  - explicit "Jump now" event prompt (flee sequences)
- **Avoidance rule:** dodges only hazards/attacks tagged **Ground**.
- Clears obstacles tagged **Vaultable**.

## Tags (authoritative gameplay)
### Attack/Hazard tags
- **High**: can be dodged by Crouch; hits Standing; typically projectiles at chest/head height.
- **Ground**: can be dodged by Vault/Jump; hits Standing/Crouch; typically ground wave / floor spikes.
- **Neutral**: hits regardless of crouch/jump unless explicitly stated (default for most attacks early).

Rules:
- Crouch only affects High.
- Vault only affects Ground.
- If an attack has no tag, treat it as Neutral.

### Obstacle tags
- **Vaultable**: requires Vault to cross (tree trunk, low barrier).
- **LowClearance**: requires Crouch to pass (fence gap, collapsed tunnel).
- **Connector**: changes elevation layer (stairs/ladder/door/ramps). Jump does not change elevation.

## Elevation layers
Minimum viable:
- **Ground**
- **Elevated**

### Moving between layers
- Only through **Connector** volumes.
- Connector defines:
  - from_layer -> to_layer
  - optional direction
  - optional interaction requirement (press key) vs auto

## Combat line of sight (LOS)
- Attacks across elevation layers require LOS.
- "LOS blocked" means:
  - cannot target, or projectile collides with a blocker
- Early slice: treat walls/railings as LOS blockers unless at an "edge" zone (optional later).

## Networking (host-authoritative)
- Clients send **intent**: crouch toggle, vault/jump request, interact connector.
- Host validates:
  - state transitions (cooldowns/durations)
  - obstacle requirements met
  - hazard avoidance resolution by tags
  - elevation changes via connectors only
- Host replicates:
  - traversal state (standing/crouch/vault)
  - elevation layer
  - position/velocity (as applicable)

## Prototype Status (Implemented)
- Current testbed implements explicit traversal states: Standing/Crouching/Vaulting.
- Crouch is hold-based and changes both movement speed and capsule height.
- Vault is contextual and gated by `Vaultable` trigger overlap.
- Vault start requires movement toward a nearby obstacle (prevents reverse/idle vault "float").
- Vault distance is computed from obstacle trigger shape + clearance for full crossing.

## VS-001 implementation notes (minimal)
For vertical slice, it's enough to demonstrate:
- One **Vaultable** obstacle (tree trunk)
- One **LowClearance** obstacle (fence gap)
- One **Ground** hazard (ground wave) avoidable by vault
- One **High** projectile avoidable by crouch
- One **Connector** to Elevated (simple tower platform) and LOS gating