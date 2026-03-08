# ADR-005: Traversal & Verticality Model (Diablo-like, Non-Precise)

## Status
Accepted

## Context
We want:
- Jump and crouch as readable, timing-based actions (not precision platforming).
- Avoiding some projectiles by crouching.
- “Flee” events with obstacles requiring jump/crouch at the right time.
- Multi-level play (towers/walls) with line-of-sight combat.

This must remain compatible with:
- host-authoritative multiplayer
- player-owned saves
- VS-001 vertical slice scope

## Decision
We will implement **Diablo-like traversal** with **rule/animation-driven** actions and **gameplay verticality**:

1) **Traversal actions are non-precise**
- Jump is a **vault/jump state** used for clearing obstacles and avoiding tagged ground effects.
- Crouch is a **low-profile state** used for passing under low clearance and avoiding tagged high attacks.
- Traversal is **timing-based** and/or trigger-based (not physics platforming).

2) **Tagged avoidance rules**
- Crouch avoids only attacks tagged as **High**.
- Jump/Vault avoids only hazards/attacks tagged as **Ground** (and clears vaultable obstacles).

3) **Verticality exists in gameplay**
- World supports at least **Ground** and **Elevated** layers (e.g., wall/tower).
- Elevation transitions occur via **connectors** (stairs/ladder/ramps/doors), not free jumping.
- Combat between elevations requires **line of sight**.

## Scope
- This ADR defines traversal semantics and gameplay verticality rules.
- It does not define world representation technology, camera implementation, or aiming-space rules in detail.

## Implications
- Characters have explicit traversal state (Standing / Crouching / Vaulting).
- Attacks and hazards must declare their clearance tag (High / Ground / Neutral).
- Obstacles must declare required traversal (Vault / Crouch / Connector).
- Networking replicates traversal state + elevation layer; host validates transitions and hit results.

## Alternatives considered
- Visual-only “fake depth” (rejected: doesn’t support tower/wall gameplay rules)
- Full platformer physics (rejected: too precise for intended feel)

## Related ADRs
- [ADR-006-world-representation.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-006-world-representation.md)
- [ADR-007-input-and-controls.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-007-input-and-controls.md)
- [ADR-016-space-model-continuous-world-navmesh-no-tile-diagonals.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-016-space-model-continuous-world-navmesh-no-tile-diagonals.md)
