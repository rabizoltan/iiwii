# ADR-006: World Representation (3D World + 3D Characters, Diablo-like Camera)

## Status
Accepted

## Context
iiWii requires:
- real gameplay verticality (ground + elevated positions like walls/towers)
- line-of-sight combat between elevations
- traversal mechanics (crouch/vault) that are timing-based, not precision platforming
- co-op host-authoritative multiplayer

We want to avoid later rework in: level building, collision, LOS, traversal, animation, and networking.

## Decision
We will implement iiWii as a **3D world with 3D characters**, using a **Diablo-like fixed/limited camera**:
- The game runs in a 3D scene space (true elevation exists).
- The camera is top-down/isometric-ish and kept fixed or tightly constrained for readability.
- Traversal (crouch/vault) remains **rule/animation-driven** (not physics platforming).
- Elevation changes happen primarily via **connectors** (stairs/ramps/ladders/doors).

## Rationale
- Makes towers/walls/stairs and LOS straightforward and consistent.
- Level blockout is fast with simple 3D geometry (placeholders first).
- 3D animations support readable crouch/vault states under a fixed camera.
- Avoids special-case “fake elevation” logic that tends to cause rework later.

## Implications
- Use 3D gameplay nodes (movement, collision, raycasts for LOS).
- Keep early movement mostly ground-aligned; avoid freeform vertical jumping.
- Define what is authoritative in multiplayer:
  - host decides hits/damage/loot/objectives
  - clients predict local movement/traversal responsiveness

## Alternatives considered
- 3D world + 2D sprite characters (rejected for now; more animation/view-angle complexity)
- 2D world with discrete layers (rejected; higher risk for LOS/elevation rework)

## Consequences
- Early prototypes can use primitive meshes (capsules/boxes) and still validate gameplay.
- Art can evolve later without rewriting core systems.
