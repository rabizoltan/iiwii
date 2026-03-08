# ADR-016: Space Model & Aiming (Continuous World + Free Aim)

## Status
Accepted

## Context
iiWii is a 3D world with a fixed/limited top-down/isometric camera.
We need stable rules for movement, aiming, projectiles, and AI pathfinding without tile/diagonal complexity.

## Decision
- The game uses a **continuous world space model** (not tile/grid movement).
- **Free aim**: the player aims at a world-space point under the mouse cursor.
- Projectiles and hit detection operate in world space (hitscan raycasts and/or physical projectiles).
- AI pathfinding uses **navmesh** on walkable surfaces.
- "Diagonal movement rules" do not exist as a gameplay concept.

(Optional level design convenience)
- Level construction may use a placement grid for alignment, but gameplay remains continuous.

## Scope
- This ADR defines movement space, aiming space, projectile space, and pathfinding-space assumptions.
- It does not define camera framing, traversal semantics, or AI behavior policy in detail.

## Implications
- We need a reliable way to get the mouse aim point:
  - cast a ray from the camera through the mouse cursor to the ground/scene
- We need clear collision layers/masks for:
  - ground/aim surface
  - LOS blockers (walls/railings)
  - characters (hurtboxes)
  - projectiles

## Consequences
- Avoids major rework in movement, aiming, projectiles, and AI.
- Supports responsive action combat and readable co-op gameplay.

## Related ADRs
- [ADR-006-world-representation.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-006-world-representation.md)
- [ADR-007-input-and-controls.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-007-input-and-controls.md)
- [ADR-017-navmesh-size-layers.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-017-navmesh-size-layers.md)
- [ADR-018-enemy-ai-nav-v1-approach.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-018-enemy-ai-nav-v1-approach.md)
