# ADR-003: Progression Ownership

## Status
Accepted

## Date
2026-02-28

## Context
Co-op sessions involve multiple players with independent investment and schedules. Shared progression ownership creates conflict and failure recovery risk.

## Decision
Progression is **player-owned**. There is **no shared town save** across a party.

## Scope
- This ADR defines ownership only.
- It does not define save schema shape, death handling details, or inventory persistence rules.

## Rationale
- Prevents grief/blocking from shared save coupling.
- Simplifies data ownership and recovery.
- Supports drop-in/drop-out co-op with different account states.

## Consequences
- Mission resolution distributes per-player progression deltas.
- Party members may have unequal town progression.
- UI and matchmaking must communicate progression differences clearly.

## Related ADRs
- [ADR-009-save-schema-v0-player-owned-json-versioned.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-009-save-schema-v0-player-owned-json-versioned.md)
- [ADR-010-session-flow-host-world-own-town-return.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-010-session-flow-host-world-own-town-return.md)
- [ADR-013-progression-split-town-knowledge-vs-hero-build.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-013-progression-split-town-knowledge-vs-hero-build.md)
