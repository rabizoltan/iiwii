# ADR-005: Traversal & Verticality Model (Diablo-like, Non-Precise)

## Status
Accepted

## Context
We want:
- Jump and crouch as readable, timing-based actions, not precision platforming.
- Avoiding some projectiles by crouching.
- flee events with obstacles requiring jump or crouch at the right time.
- multi-level play with line-of-sight combat.

This must remain compatible with:
- host-authoritative multiplayer
- player-owned saves
- VS-001 vertical slice scope

## Decision
We will implement **Diablo-like traversal** with **rule/animation-driven** actions and **gameplay verticality**:

1. **Traversal actions are non-precise**
- Jump is a **vault/jump state** used for clearing obstacles and avoiding tagged ground effects.
- Crouch is a **low-profile state** used for passing under low clearance and avoiding tagged high attacks.
- Traversal is **timing-based** and or trigger-based, not physics platforming.

2. **Tagged avoidance rules**
- Crouch avoids only attacks tagged as **High**.
- Jump/Vault avoids only hazards or attacks tagged as **Ground**, and clears vaultable obstacles.

3. **Verticality exists in gameplay**
- World supports at least **Ground** and **Elevated** layers, for example wall or tower play.
- Elevation transitions occur via **connectors** such as stairs, ladders, ramps, or doors, not free jumping.
- Combat between elevations requires **line of sight**.

4. **Explicit displacement mobility may coexist with traversal without replacing it**
- A short dodge or longer dash style mobility action may exist as an authored displacement ability.
- That mobility action does not replace crouch, vault, or connector-based traversal semantics.
- Blink or teleport behavior remains a separate later design decision.

## Scope
- This ADR defines traversal semantics and gameplay verticality rules.
- It does not define world representation technology, camera implementation, or aiming-space rules in detail.

## Current Prototype Note
- The current playable runtime now includes a displacement-based mobility foundation that can be tuned as a short `dodge` or longer `dash`.
- Contextual low-obstacle vault traversal is now implemented as authored `VaultTrigger`-driven runtime behavior.
- Physical crouch movement-state behavior is now implemented as hold-to-crouch with clearance-gated stand-up.
- Tagged hazard avoidance semantics and connector-driven traversal remain future follow-up work.

## Implications
- Characters have explicit traversal state such as Standing, Crouching, or Vaulting.
- Attacks and hazards must declare their clearance tag: High, Ground, or Neutral.
- Obstacles must declare required traversal: Vault, Crouch, or Connector.
- Networking replicates traversal state plus elevation layer; host validates transitions and hit results.
- A separate mobility action can exist alongside traversal rules, but it should stay authored and rule-driven rather than becoming freeform platforming movement.

## Alternatives considered
- Visual-only fake depth (rejected: does not support tower or wall gameplay rules)
- Full platformer physics (rejected: too precise for intended feel)

## Related ADRs
- [ADR-006-world-representation.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-006-world-representation.md)
- [ADR-007-input-and-controls.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-007-input-and-controls.md)
- [ADR-016-space-model-continuous-world-navmesh-no-tile-diagonals.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-016-space-model-continuous-world-navmesh-no-tile-diagonals.md)
