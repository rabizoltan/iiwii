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
- “Diagonal movement rules” do not exist as a gameplay concept.

(Optional level design convenience)
- Level construction may use a placement grid for alignment, but gameplay remains continuous.

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
