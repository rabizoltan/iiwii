# Traversal (Vault, Crouch) + Verticality
Category: Gameplay System
Role: Reference Contract
Last updated: 2026-03-30
Last validated: manual playtesting in editor during vault slice implementation

## Goals
- Provide Diablo-like, timing-based traversal without precision platforming.
- Keep vault traversal readable, contextual, and authored rather than geometry-guessed.
- Preserve a clean design boundary between low obstacle vaulting and future climb-up mechanics.

## Non-goals (for now)
- Physics-driven platforming.
- Freeform vertical movement outside authored connectors.
- Mixing low obstacle vaulting with full climb-up or mantle behavior in the same first slice.

## Player Traversal States
### Standing
Default state. Full movement + standard hit profile.

### Crouching
- Planned follow-up, not current runtime truth.

### Vaulting
Short-duration traversal state.
- Triggered by `Space` plus a valid authored vault opportunity.
- Requires active movement intent toward the obstacle; idle `Space` does not start vault.
- Returns the player to roughly the same floor level on the far side of the obstacle.
- Locks regular locomotion, attack, and mobility during travel.
- Uses temporary enemy-body ghosting during the committed motion, then restores normal collision with soft overlap cleanup if needed.

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
  - long table or trunk when explicitly authored

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

## Current Authored Vault Model
### Shared Trigger Pattern
- Vault traversal is authored through `VaultTrigger`.
- `VaultTrigger` is the activation `Area3D` and obstacle-specific rules container.
- The blue trigger box means: the player is inside an obstacle-authored activation region.
- The trigger box is not the landing point by itself.

### Anchor Pattern
Current authored anchors are:
- `EntryFaceAnchor`
- `ExitFaceAnchor`
- `EntryLandingAnchor`
- `ExitLandingAnchor`

Meaning:
- face anchors define the two crossing sides of the obstacle
- landing anchors define the landing references on the far sides

### Directionality
Current directionality choices:
- `ENTRY_TO_EXIT`
- `EXIT_TO_ENTRY`
- `BIDIRECTIONAL`

### Traversal Models
Current trigger traversal models:
- `FIXED_ENDPOINT`
  - best for short simple obstacles
- `STRIP_OFFSET`
  - best for long straight obstacles
  - preserves where along the obstacle the player started
  - avoids pulling the player toward one shared middle landing point

## Current Runtime Rules
- Candidate selection prefers valid authored triggers in front of the player, then picks the best valid candidate by score.
- Current forward-facing tolerance starts from the player controller export `vault_facing_angle_degrees = 65`.
- Current start distance starts from `vault_activation_distance = 1.2` plus trigger-side contact/overlap tolerances.
- Landing must resolve to valid floor with clearance and same-floor intent.
- Nearby enemy bodies should not hard-block vault start by themselves.
- Vault motion is code-driven, committed, and readable rather than animation-root-motion-driven.
- Arc height derives from trigger `obstacle_height + arc_clearance`, then clamps through player-side arc limits.
- Vault remains a low-obstacle crossing tool, not a general elevation-change mechanic.

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

## Future-Slice Context (Not Part Of The Current Vault Slice)
The sections below preserve broader traversal and verticality context for later slices.
They are not part of the current low-obstacle vault implementation scope unless a future slice explicitly reactivates them.

## Tags (future-facing gameplay context)
### Attack/Hazard tags
- **High**: can be dodged by Crouch; hits Standing; typically projectiles at chest/head height.
- **Ground**: can be dodged by Vault/Jump; hits Standing/Crouch; typically ground wave / floor spikes.
- **Neutral**: hits regardless of crouch/jump unless explicitly stated.

### Obstacle tags
- **Vaultable**: requires Vault to cross.
- **LowClearance**: requires future Crouch to pass.
- **Connector**: changes elevation layer. Vault does not change elevation.

## Elevation Layers
Minimum viable future direction:
- **Ground**
- **Elevated**

Vault does not become a general elevation-change mechanic in the first slice.

## Networking (Host-Authoritative Future Target)
- Clients send traversal intent.
- Host validates traversal state changes and authored obstacle requirements.
- Host replicates traversal state and position.

## Broader Vertical Slice Target (Future Context)
- Standing, crouching, and vaulting remain the intended traversal vocabulary.
- Crouch is still future scope.
- Vault is now the implemented authored low-obstacle crossing baseline.
- Mantle remains the later elevation-gain follow-up.
