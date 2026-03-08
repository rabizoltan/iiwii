# Collision Layers & Masks (Godot 3D)

## Purpose
Define a stable collision-layer convention to avoid rework in:
- mouse aiming (raycasts)
- projectile/hitscan collision
- line-of-sight (LOS)
- traversal triggers (vault/crouch/connectors)

This project uses a continuous 3D space model and free aim.

## Layer Naming (v0)
1. `WorldSolid`
- Blocks movement and shots.
- Used for LOS blockers.

2. `GroundAim`
- Surfaces used for cursor/world aim picking.

3. `PlayerBody`
- Player movement collision.

4. `EnemyBody`
- Enemy movement collision.

5. `Hurtbox`
- Damage-receiving collision.

6. `Projectile`
- Physical projectile layer (optional in hitscan prototype).

7. `Trigger`
- Non-blocking gameplay trigger areas.

8. `Interactable`
- Optional interact prompt ray target.

## Implemented Testbed Masks
### Aim-pick ray (camera cursor ray)
- Mask: `WorldSolid (1) + GroundAim (2) + Hurtbox (16)`
- Numeric: `19`
- `collide_with_bodies = true`
- `collide_with_areas = true`
- Excludes player-owned nodes.

### Shot ray (player chest -> aim point)
- Mask: `WorldSolid (1) + Hurtbox (16)`
- Numeric: `17`
- WorldSolid blocks before Hurtbox.

### Traversal detector
- Player `VaultDetector` overlaps trigger layer used by `Vaultable` areas.

## Notes
- Keep `GroundAim` enabled on floor surfaces.
- Keep vault/crouch/extract zones non-blocking trigger areas.
- Separate body and hurtbox colliders where possible.
- For top-down camera parallax, cursor pick and shot origin differ; this is expected. Use fallback validation rules deliberately and keep them documented.