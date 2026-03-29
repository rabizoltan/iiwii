# Traversal (Vault, Crouch) + Verticality
Category: Gameplay System
Role: Reference Contract
Last updated: 2026-03-29
Last validated: pending

## Goals
- Provide Diablo-like, timing-based traversal (no precision platforming).
- Support flee obstacles (jump/crouch prompts).
- Support multi-level play (ground vs tower/wall) with LOS-based combat.
- Keep vault traversal readable, contextual, and authored rather than geometry-guessed.

## Non-goals (for now)
- Physics-driven platforming (ledge grabs, variable jump height, airborne steering precision).
- Freeform vertical movement outside connectors (no "jump anywhere to any height").
- Mixing low obstacle vaulting with full climb-up or mantle behavior in the same first slice.

## Player traversal states
### Standing
Default state. Full movement + standard hit profile.

### Crouching
- Enter/exit via input (or forced by "low clearance zones").
- Movement speed reduced (tunable).
- **Avoidance rule:** dodges only attacks/hitboxes tagged **High**.

### Vaulting
Short-duration traversal state.
- Triggered by input + a valid authored vault traversal opportunity.
- For authored obstacle vaulting, v1 should require active movement intent toward the obstacle together with the vault input rather than allowing idle `Space` activation.
- **Avoidance rule:** dodges only hazards/attacks tagged **Ground**.
- Clears obstacles tagged **Vaultable**.
- Returns the player to roughly the same floor level on the far side of the obstacle.

## Vault vs Mantle Boundary
### Vault
- Crosses **over** a low obstacle.
- Starts from one side and lands on the far side in one committed motion.
- Returns to nearly the same floor level.
- Typical examples:
  - fallen tree
  - bench
  - low barricade
  - short fence segment
  - sandbag line

### Mantle / Climb-Up
- Moves **up onto** something meaningfully higher.
- Requires ledge or top-surface acquisition rather than simple obstacle crossing.
- Typical examples:
  - crate top
  - platform lip
  - rooftop edge
  - higher wall ledge

Rule of thumb:
- if the move goes **over** a low obstacle and back to roughly the same floor level, it is **Vault**
- if the move gets the player **up onto** a meaningfully higher surface, it is **Mantle / Climb-Up**

Mantle remains a separate later slice and should not be folded into first-pass vault implementation.

## Future Mantle Notes
These notes preserve the currently agreed future direction without opening a mantle implementation slice yet.

- Mantle or climb-up should mean getting onto a meaningfully higher surface.
- Mantle should acquire a ledge or top surface rather than simply crossing a low obstacle.
- Mantle should likely use its own authored traversal affordance, such as `MantleLink` or `ClimbUpTrigger`, instead of reusing low-obstacle vault data blindly.
- Mantle v1 should stay smaller than a full climbing system:
  - no ledge hang
  - no shimmy
  - no wall climb
  - no chained parkour

### Likely Mantle Height Bands
A future mantle slice should likely distinguish at least two mantle bands:
- **Low mantle**
  - around hip or waist height
  - smaller elevation gain
  - examples: crate edge, low platform lip, short raised ledge
- **High mantle**
  - around chest to arm-reach height
  - larger but still reachable climb-up
  - examples: taller ledge, raised walkway edge, higher rooftop lip

This is preferred over a single generic mantle because different height bands usually want different validation limits, motion timing, animation treatment, and gameplay readability.

Good future mantle examples:
- crate top
- platform lip
- rooftop edge
- raised walkway edge

## Future-Slice Context (Not Part Of The Current Vault Slice)
The sections below preserve broader traversal and verticality context for later slices.
They are not part of the current low-obstacle vault implementation scope unless a future slice explicitly reactivates them.

## Tags (future-facing gameplay context)
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
- **Connector**: changes elevation layer (stairs/ladder/door/ramps). Vault does not change elevation.

## Authored Traversal Affordances
Best-practice baseline for this project:
- Traversal should be **explicitly authored** on the environment.
- Low obstacle vaulting should use a dedicated traversal node or component such as `VaultTrigger` or `TraversalMarker`.
- The player runtime should own vault execution, while the obstacle-side traversal node should own the obstacle-specific traversal data.

The authored traversal node should define at least:
- traversal type, currently `vault`
- entry region or valid approach side
- start alignment or anchor
- exit landing point or anchor
- optional traversal duration or local tuning overrides

Recommended v1 selection and directionality rules:
- prefer valid vault nodes in front of the player, then choose the nearest valid candidate
- use a forgiving front-facing cone; roughly `45` degrees is the intended starting point
- require active movement intent toward the chosen candidate
- default to one-way authored directionality
- allow bidirectional vaulting only when the obstacle is explicitly authored for both sides
- prefer a simple `VaultTrigger`-style setup with entry and exit anchors for v1 rather than a more general link model

Recommended v1 tuning rules:
- require a short readable activation distance near the obstacle rather than long-range triggering
- derive the vault arc from obstacle height plus a small clearance margin
- keep enemy end-of-vault overlap resolution gentle so traversal remains readable and does not become a shove attack

This is preferred over pure geometry guessing because it is more reliable, easier to debug, clearer for level design, and easier to extend later to mantle, crouch-pass, ladder, or connector traversal.

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

Vault does not become a general elevation-change mechanic in the first slice.

## Combat line of sight (LOS)
- Attacks across elevation layers require LOS.
- "LOS blocked" means:
  - cannot target, or projectile collides with a blocker
- Early slice: treat walls/railings as LOS blockers unless at an "edge" zone (optional later).

## Networking (host-authoritative future target)
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

## Broader Vertical Slice Target (Future Context)
- Traversal should support explicit `Standing`, `Crouching`, and `Vaulting` states.
- Crouch should be hold-based and should change both movement speed and capsule height.
- Vault should be contextual and gated by a nearby authored `Vaultable` traversal node.
- Vault start should require a valid approach, active movement intent, and should not trigger from an idle misalignment.
- Vault should land on the far side of the obstacle without becoming climb-up or mantle behavior.

## Broader VS-001 Notes (Future Context)
For the broader traversal-and-verticality vision, it is enough to demonstrate:
- One **Vaultable** obstacle (tree trunk)
- One **LowClearance** obstacle (fence gap)
- One **Ground** hazard (ground wave) avoidable by vault
- One **High** projectile avoidable by crouch
- One **Connector** to Elevated (simple tower platform) and LOS gating
