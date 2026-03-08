# ADR-007: Input & Controls (PC-first WASD + Mouse Aim)

## Status
Accepted

## Context
iiWii targets a 1-4 player co-op PvE game and is currently being built through a singleplayer-first vertical slice with:
- a fixed/limited top-down/isometric camera
- timing-based traversal (crouch/vault) rather than precision platforming
- LOS-based ranged combat and abilities
- host-authoritative multiplayer (clients send intent)

We need an input baseline that feels responsive and supports these mechanics without later rewrites.

## Decision
We will implement a **PC-first control scheme**:
- **Movement:** WASD
- **Aiming:** mouse aim (cursor/world aim point)
- **Actions:** key/mouse button based (primary/secondary + abilities)
- **Traversal:** dedicated crouch + vault/jump inputs (timing-based)

We will later support controllers, but the first implementation targets keyboard/mouse.

## Default bindings (initial)
- Move: WASD
- Aim: Mouse position (world aim point)
- Primary attack: Left Mouse Button
- Secondary attack / ability: Right Mouse Button
- Interact: E
- Crouch: Ctrl (hold by default; optional toggle later)
- Vault/Jump: Space (contextual; see below)
- Dodge: Shift

## Vault/Jump behavior (non-precise)
- Vault/Jump is **contextual**:
  - triggers when near a Vaultable obstacle, or during a flee obstacle prompt
  - otherwise does nothing (or plays a fail sound/feedback later)
- Vault/Jump is used for:
  - clearing Vaultable obstacles
  - avoiding hazards tagged as Ground (validated by host)

## Crouch behavior
- Crouch is used for:
  - passing LowClearance zones
  - avoiding attacks tagged as High (validated by host)

## Implications
- Input actions represent **intent** (especially in multiplayer).
- Player controller must support:
  - responsive local feel (local prediction for movement/traversal)
  - authoritative correction from host snapshots
- UI must not directly change gameplay state; it triggers intents/commands.

## Alternatives considered
- Click-to-move ARPG controls (rejected: conflicts with timing-based traversal/avoidance)
- Controller-first twin-stick (deferred: would drive early UI/aim-assist decisions)
