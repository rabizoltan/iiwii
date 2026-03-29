# Player Mantle / Climb-Up Slice

## Status
- `planned`

## Purpose
- Preserve the future mantle or climb-up design direction without mixing it into the current vault slice.
- Define climb-up as a separate traversal family for getting onto meaningfully higher surfaces.
- Keep future mantle scope narrower than a full climbing or parkour system.

## Current Role
- This is a future planning document, not an active implementation slice.
- It exists so future mantle work does not restart from zero.
- Runtime truth for the current project still belongs to [movement-spec.md](d:/Game/DEV/iiWii/iiwii/docs/systems/movement-spec.md) and [traversal-and-verticality.md](d:/Game/DEV/iiWii/iiwii/docs/systems/traversal-and-verticality.md).

## Design Direction
1. Mantle or climb-up is separate from vault.
2. Mantle means getting onto a meaningfully higher surface.
3. Mantle should acquire a ledge or top surface rather than simply crossing a low obstacle.
4. Mantle should remain contextual and authored rather than becoming free jump or wall-climb behavior.
5. Mantle v1 should stay smaller than a full climbing system.

## Mantle Definition
Mantle or climb-up should mean:
- move onto a meaningfully higher surface
- acquire a ledge or top surface rather than just crossing a low obstacle
- end on top of the destination surface rather than on the far side at the same height

Good future examples:
- crate top
- low platform lip
- rooftop edge with clear top surface
- raised walkway edge

Not part of mantle v1:
- hanging state
- shimmying
- arbitrary wall climb
- chained parkour
- moving climb targets

## Mantle Height Bands
A future mantle slice should likely distinguish at least two mantle bands:

### Low Mantle
- around hip or waist height
- smaller elevation gain
- examples:
  - crate edge
  - low platform lip
  - short raised ledge

### High Mantle
- around chest to arm-reach height
- larger but still reachable climb-up
- examples:
  - taller ledge
  - raised walkway edge
  - higher rooftop lip

Why keep these bands:
1. different validation limits
2. different travel timing and commitment
3. likely different animation treatment
4. clearer gameplay readability

## Likely Authored Pattern
If a future mantle slice is opened, it should probably start with:
- contextual activation rather than a free jump
- a dedicated authored traversal node such as `MantleLink` or `ClimbUpTrigger`
- valid approach side and destination-surface checks
- clear top-surface landing validation
- strict separation from low obstacle vault data

## Why Mantle Should Stay Separate From Vault
1. It changes elevation rather than just obstacle crossing.
2. It needs ledge or top-surface validation.
3. It may need different authored affordances than vault.
4. It is more likely to interact with camera, enemy reachability, and level-routing assumptions.

## Acceptance Direction For A Future Slice
A future active mantle slice should likely prove:
1. low mantle onto a small raised surface
2. high mantle onto a taller reachable ledge
3. invalid destination surfaces block mantle start
4. mantle does not silently replace vault behavior
5. mantle remains smaller than a full climbing system

## Related Documents
- [traversal-and-verticality.md](d:/Game/DEV/iiWii/iiwii/docs/systems/traversal-and-verticality.md)
- [movement-spec.md](d:/Game/DEV/iiWii/iiwii/docs/systems/movement-spec.md)
- [player-vault-traversal-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/active/player-vault-traversal-slice.md)
- [player-traversal-and-movement-slice-roadmap.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/roadmaps/player-traversal-and-movement-slice-roadmap.md)
