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
- **Mobility:** dedicated dodge/dash-style escape input on `Shift`

## Scope
- This ADR defines input and control conventions.
- It does not define world representation technology or the low-level movement space model.

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

## Current Prototype Note
- The current runtime baseline now includes one shared mobility action on `Shift`.
- That mobility action is implemented as a tunable foundation that can behave like either a short `dodge` or a longer `dash`.
- Vault and crouch remain planned traversal follow-ups and are not yet part of the playable runtime baseline.

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
- The current movement runtime should treat `Shift` mobility as one shared ability path with data/tuning-driven profiles rather than two unrelated mechanics.

## Alternatives considered
- Click-to-move ARPG controls (rejected: conflicts with timing-based traversal/avoidance)
- Controller-first twin-stick (deferred: would drive early UI/aim-assist decisions)

## Related ADRs
- [ADR-005-traversal-and-verticality-model.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-005-traversal-and-verticality-model.md)
- [ADR-006-world-representation.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-006-world-representation.md)
- [ADR-008-multiplayer-replication-style.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-008-multiplayer-replication-style.md)
- [ADR-016-space-model-continuous-world-navmesh-no-tile-diagonals.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-016-space-model-continuous-world-navmesh-no-tile-diagonals.md)
