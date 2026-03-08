# ADR-018: Enemy AI Navigation v1: Threat + Ring/Donut Goals + Stuck Recovery

## Status
Accepted

## Context
Directly pathing enemies to the player position causes:
- clumping
- corner-edge sticking
- frequent wall-hitting attempts when LOS is blocked
We need stable behavior for ~100 enemies and a design that can be extended with real threat sources (damage/abilities) later.

## Decision
Adopt a goal-based navigation approach:
- Target selection uses a threat table (v1 distance-only) with hysteresis to prevent rapid switching.
- Enemies move toward a goal point near the target:
  - Melee: ring gather candidates
  - Ranged: donut positioning candidates + LOS peeking
- Attacks require LOS (raycast) to prevent hitting through walls.
- Stuck detection is progress-based and triggers a recovery ladder that changes the goal/approach.

Updates are staggered on timers (no per-frame retarget/repath).

## Scope
- This ADR defines enemy navigation and combat-positioning behavior policy.
- It does not define the underlying navmesh space model or nav-layer authoring strategy by itself.

## Rules
1) Goal selection must prioritize closest reachable goal by path length (no random far-side slots).
2) Slotting is soft: occupancy penalty influences choice but does not hard-block.
3) Attack requires LOS (hard gate).
4) Stuck recovery must change the situation (new goal, detour, widened constraints), never only repath to same goal.

## Consequences
Positive:
- Natural gather and fight behavior without perfect surround requirements.
- Ranged enemies behave tactically (kite strafe, peek for LOS).
- Much higher robustness around corners and crowds.

Negative:
- More moving parts (modules) than a single chase script.
- Requires debug overlays and config tuning for best feel.

## Alternatives considered
- Pure physics pushing + direct chase: causes jams and corner sticking.
- Random orbit/slot assignment: causes enemies to pick far-side goals and look dumb.

## Related ADRs
- [ADR-016-space-model-continuous-world-navmesh-no-tile-diagonals.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-016-space-model-continuous-world-navmesh-no-tile-diagonals.md)
- [ADR-017-navmesh-size-layers.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-017-navmesh-size-layers.md)
