# ADR-009: Save Schema v0 (Player-Owned, JSON, Versioned)

## Status
Accepted

## Context
iiWii uses:
- player-owned progression (each player keeps their own save)
- co-op missions as shared instances, with host authority during the run
- mission end triggers local writeback for each player

We need a minimal save schema that:
- supports VS-001 (write a JSON save with timestamp + counters)
- will not force rework later (stable keys, versioned format, room to extend)
- supports perma-death heroes + persistent town/mastery unlocks

## Decision
We will use a **player-owned, local, versioned JSON save** (schema v0).

- Storage: local file under Godot `user://`
- Format: JSON
- Versioning: `schema_version` is required and starts at `0`
- Ownership: each player writes only their own save; the host never writes saves for guests
- Scope note: `schema v0` remains intentionally minimal. Inventory-specific persistence details are deferred until inventory becomes an active implementation target.

## Scope
- This ADR defines save-foundation rules and minimal schema expectations.
- It does not fully define inventory persistence shape.
- It does not replace gameplay ADRs that define progression ownership, death, or town behavior.

## Save writes (when)
- At mission end (extract success / wipe / abort): write results to local save
- At town changes that affect persistent progression (upgrades/unlocks): write
- On clean quit: write (best-effort)

## Save structure (high level)
The save contains:
- `meta` (schema, timestamps)
- `town` (persistent progression)
- `town.weapon_knowledge` (persistent max weapon XP + unlocked skills by weapon type)
- `roster` (heroes list; heroes can be alive or dead)
- `run` (optional transient block; may be absent in v0)

## Stability rules (avoid rework)
- Key names in v0 are stable: do not rename without a migration step.
- Additive changes are allowed (new fields with defaults).
- Breaking changes require bumping `schema_version` and a migration function.

## Consequences
- VS-001 can implement a save stub immediately (timestamp + town weapon knowledge baseline).
- Future systems (talents, inventory, crafting) can extend the same file without rewriting.
- Multiplayer remains consistent with player-owned progression and own-town return after mission end.
- Inventory persistence is explicitly treated as a later schema extension, not as a required part of `ADR-009` v0.

## Related ADRs
- [ADR-003-progression-ownership.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-003-progression-ownership.md)
- [ADR-010-session-flow-host-world-own-town-return.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-010-session-flow-host-world-own-town-return.md)
- [ADR-011-hero-death-safe-state-switching-and-party-continuity.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-011-hero-death-safe-state-switching-and-party-continuity.md)
- [ADR-015-inventory-model-loadout-backpack-town-chest.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-015-inventory-model-loadout-backpack-town-chest.md)
