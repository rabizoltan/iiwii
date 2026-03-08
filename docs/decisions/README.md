# ADR Index

This folder contains accepted architectural decision records for `iiwii`.

## How To Use These ADRs
- Read ADRs before architecture or system docs when the task touches a major decision boundary.
- If an ADR conflicts with another project document, the ADR wins.
- Prefer the narrowest relevant ADR cluster instead of reading the whole folder every time.

## Current ADR Clusters

### Platform And Runtime Foundation
- [ADR-001-engine-choice.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-001-engine-choice.md)
- [ADR-002-language-strategy.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-002-language-strategy.md)

### Progression, Save, Death, Town
- [ADR-003-progression-ownership.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-003-progression-ownership.md)
- [ADR-009-save-schema-v0-player-owned-json-versioned.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-009-save-schema-v0-player-owned-json-versioned.md)
- [ADR-010-session-flow-host-world-own-town-return.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-010-session-flow-host-world-own-town-return.md)
- [ADR-011-hero-death-safe-state-switching-and-party-continuity.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-011-hero-death-safe-state-switching-and-party-continuity.md)
- [ADR-012-town-buildings-and-meta-progression.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-012-town-buildings-and-meta-progression.md)
- [ADR-013-progression-split-town-knowledge-vs-hero-build.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-013-progression-split-town-knowledge-vs-hero-build.md)
- [ADR-014-weapon-mastery-granularity-coarse-types-first.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-014-weapon-mastery-granularity-coarse-types-first.md)
- [ADR-015-inventory-model-loadout-backpack-town-chest.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-015-inventory-model-loadout-backpack-town-chest.md)

### Multiplayer And Authority
- [ADR-004-networking-model.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-004-networking-model.md)
- [ADR-008-multiplayer-replication-style.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-008-multiplayer-replication-style.md)
- [ADR-010-session-flow-host-world-own-town-return.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-010-session-flow-host-world-own-town-return.md)

### World, Traversal, Input, Space
- [ADR-005-traversal-and-verticality-model.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-005-traversal-and-verticality-model.md)
- [ADR-006-world-representation.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-006-world-representation.md)
- [ADR-007-input-and-controls.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-007-input-and-controls.md)
- [ADR-016-space-model-continuous-world-navmesh-no-tile-diagonals.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-016-space-model-continuous-world-navmesh-no-tile-diagonals.md)

### AI And Navigation
- [ADR-017-navmesh-size-layers.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-017-navmesh-size-layers.md)
- [ADR-018-enemy-ai-nav-v1-approach.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-018-enemy-ai-nav-v1-approach.md)

## Important Notes
- `ADR-009` is intentionally minimal as the save-foundation ADR.
- `ADR-015` defines the inventory model, but inventory persistence shape is deferred to a later save-schema extension.
- `ADR-011`, `ADR-012`, and `ADR-013` are complementary:
  - `ADR-011` covers hero death and session continuity
  - `ADR-012` covers town persistence
  - `ADR-013` covers the hero-bound vs town-bound progression split

## Current Priority
- Most relevant ADRs for the current milestone:
  - [ADR-005-traversal-and-verticality-model.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-005-traversal-and-verticality-model.md)
  - [ADR-007-input-and-controls.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-007-input-and-controls.md)
  - [ADR-016-space-model-continuous-world-navmesh-no-tile-diagonals.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-016-space-model-continuous-world-navmesh-no-tile-diagonals.md)
  - [ADR-017-navmesh-size-layers.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-017-navmesh-size-layers.md)
  - [ADR-018-enemy-ai-nav-v1-approach.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-018-enemy-ai-nav-v1-approach.md)
