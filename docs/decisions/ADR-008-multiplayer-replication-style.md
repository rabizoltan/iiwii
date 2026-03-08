# ADR-008: Multiplayer Replication Style (Hybrid + Local Prediction)

## Status
Accepted

## Context
iiWii is a 1-4 player co-op PvE game with a host-authoritative simulation.
We want:
- responsive controls (movement, crouch/vault feel instant)
- consistent outcomes (combat, loot, objectives do not desync)
- a network approach that will not force a big rewrite later

Definitions (plain language):
- **Local prediction**: your own client shows your action immediately while the host still decides what is ultimately true.
- **Replication**: how the host sends game updates to other players.

Replication styles:
- **Snapshots** = current state (positions, health, states)
- **Events** = discrete actions (spawn, damage dealt, objective changed)
- **Hybrid** = use both (events for important actions plus snapshots for correction)

## Decision
We will use a **hybrid replication model** with **limited local prediction**.

### 1. Local prediction (client-side)
Clients predict only their own:
- movement
- traversal state (`Standing`, `Crouch`, `Vault`)
- local animation responsiveness

Clients do not decide truth for:
- damage results or health changes
- loot drops
- objective progress or extraction success
- enemy AI decisions

### 2. Host authority (source of truth)
The host validates and decides:
- hits and damage outcomes, including avoidance validation
- enemy AI and spawning
- loot drops and rewards
- mission objectives and extraction

### 3. Replication (host to clients)
Use snapshots at a steady rate for:
- player positions and traversal states
- enemy positions and basic state

Use events for discrete actions:
- spawns and despawns
- damage results
- objective state changes
- extraction triggered or completed

### 4. Corrections
- Clients smoothly correct toward host snapshots if local prediction differs.
- The host can snap a client if divergence becomes large.

## Scope
- This ADR defines replication style and authority boundaries.
- It does not define Steam lobby plumbing in detail.
- It does not define save ownership or post-mission writeback rules.

## Implications
- All gameplay-relevant state has an authoritative owner: the host.
- Clients send intent, not outcomes.
- Attacks and hazards should remain expressible in a way the host can validate consistently.
- Visual-only effects can be client-side, but must not affect authoritative outcomes.

## Consequences
Positive:
- Controls can feel responsive even with latency.
- Outcomes remain consistent across players.
- The model can start simple and become more refined later.

Negative:
- Correction logic is required.
- State ownership must remain explicit across gameplay systems.

## Related ADRs
- [ADR-004-networking-model.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-004-networking-model.md)
- [ADR-007-input-and-controls.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-007-input-and-controls.md)
- [ADR-010-session-flow-host-world-own-town-return.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-010-session-flow-host-world-own-town-return.md)
