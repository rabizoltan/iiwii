# ADR-008: Multiplayer Replication Style (Hybrid + Local Prediction)

## Status
Accepted

## Context
iiWii is a 1–4 player co-op PvE game with a host-authoritative simulation.
We want:
- responsive controls (movement, crouch/vault feel instant)
- consistent outcomes (combat, loot, objectives do not desync)
- a network approach that won’t force a big rewrite later

Definitions (plain language):
- **Local prediction**: your own client shows your action immediately (e.g., you start moving right away),
  while the host still decides what is ultimately true.
- **Replication**: how the host sends game updates to other players.

Replication styles:
- **Snapshots** = “here’s the current state” (positions, health, states)
- **Events** = “this happened” (spawn, damage dealt, objective changed)
- **Hybrid** = use both (events for important actions + snapshots for correction)

## Decision
We will use a **Hybrid replication model** with **limited local prediction**:

1) **Local prediction (client-side)**
- Clients predict only their own:
  - movement
  - traversal state (Standing/Crouch/Vault)
  - local animation responsiveness
- Clients do NOT decide “truth” for:
  - damage results / health changes
  - loot drops
  - objective progress / extraction success
  - enemy AI decisions

2) **Host authority (source of truth)**
- The host validates and decides:
  - hits/damage outcomes (including whether crouch/jump avoided a tagged attack)
  - enemy AI and spawning
  - loot drops and rewards
  - mission objectives + extraction

3) **Replication (host › clients)**
- **Snapshots** at a steady rate for:
  - player positions + traversal states
  - enemy positions + basic state (alive/dead) and later health
- **Events** for discrete actions:
  - spawns/despawns (enemies, projectiles, loot)
  - damage results (who hit who, how much)
  - objective state changes (start/complete/fail)
  - extraction triggered/completed

4) **Corrections**
- Clients smoothly correct toward host snapshots if local prediction differs.
- The host can “snap” a client if divergence becomes large.

## Implications
- All gameplay-relevant state has an authoritative owner (host).
- Clients send **intent** (inputs), not outcomes:
  - “I pressed crouch”, “I requested vault”, “I fired weapon”
- Attacks/hazards must be tagged (High/Ground/Neutral) so the host can validate avoidance consistently.
- Visual-only effects can be client-side, but must not affect authoritative outcomes.

## Consequences
- Controls feel responsive even with latency.
- Outcomes remain consistent across players.
- The design scales: we can start simple (few events, coarse snapshots) and refine later without rewriting core systems.
