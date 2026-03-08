# ADR-017: Navmesh Size Layers (Small/Medium/Large)

## Status
Accepted

## Context
Enemy sizes vary (different capsule radii/heights). A single navmesh tends to produce:
- Paths that hug obstacle corners too tightly for large enemies
- Increased corner wedge sticking when CharacterBody3D collides while following path
We also need per-enemy traversal rules (vault/crouch/jump), and we want those to be configurable.

## Decision
Use 3 overlapping navigation meshes filtered by navigation layers:
- NavRegion_Small  (nav layer bit 1)
- NavRegion_Medium (nav layer bit 2)
- NavRegion_Large  (nav layer bit 3)

All three meshes bake from the same source geometry group: "Navigation".

Traversal capabilities should use NavigationLink3D with separate nav bits >= 4 (capability bits). Regions should use only size bits (1..3).

## Scope
- This ADR defines navmesh layering strategy for enemy size and traversal capability filtering.
- It does not define enemy behavior policy, target selection, or combat positioning logic.

## Rules
1) Each enemy uses exactly ONE size bit (1..3).
2) Capability bits (4+) are additive and only used on NavigationLink3D, not on regions.
3) Navmesh baking source group name is "Navigation" (single source of truth).

## Consequences
Positive:
- Large enemies naturally get safer clearance around corners and obstacles.
- Reduced corner sticking and fewer clearance-related path failures.
- Clean separation between size constraints and traversal capability constraints.

Negative:
- Authoring overhead (3 meshes/regions).
- Must keep layer mapping consistent across scenes and enemy configs.

## Alternatives considered
- Single largest-safe navmesh: simplest but prevents small enemies from using narrow spaces.
- Runtime nav carving: more complex and higher risk for perf/bugs in v1.

## Related ADRs
- [ADR-016-space-model-continuous-world-navmesh-no-tile-diagonals.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-016-space-model-continuous-world-navmesh-no-tile-diagonals.md)
- [ADR-018-enemy-ai-nav-v1-approach.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-018-enemy-ai-nav-v1-approach.md)
