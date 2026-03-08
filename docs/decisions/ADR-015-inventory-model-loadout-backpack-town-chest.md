# ADR-015: Inventory Model (Loadout + Backpack + Town Chest)

## Status
Accepted

## Context
iiWii has:
- permadeath heroes
- town meta progression (persistent buildings/resources/knowledge)
- missions where heroes loot gear and resources

We need a stable inventory model that supports:
- equipped items (combat readiness)
- loot gathered during missions
- persistent storage in town
- clear death/survival consequences

## Decision
Inventory is split into three layers:

1) **Loadout (equipped on hero)**
- Items currently equipped (weapons, armor, etc.)
- Affects gameplay immediately

2) **Backpack (carried during mission)**
- Items and resources picked up during a mission
- May be transferred to Town Chest after mission end

3) **Town Chest (persistent storage)**
- Player-owned storage in town
- Stores items/resources that persist across missions and hero changes
- Used to gear up new heroes

Schema note:
- This ADR defines the inventory model and intended persistence behavior.
- It does **not** force inventory fields into `ADR-009` schema v0.
- The concrete save shape for inventory is deferred until inventory becomes an active implementation milestone.

## Scope
- This ADR defines the inventory ownership model and outcome behavior.
- It does not define the minimal save-foundation schema.
- It does not replace the ADRs that define progression ownership, town persistence, or hero death flow.

### Survival rule
- If the hero **survives/extracts**, they keep everything:
  - their loadout
  - backpack contents (then can deposit to chest)
  - earned resources
- If the hero **dies**, the hero is lost and everything on them is lost:
  - loadout + backpack are lost with the hero
  - town chest, town resources, town buildings, and town knowledge remain

## Implications
- When inventory implementation becomes active, save data must eventually store:
  - town chest contents
  - per-hero loadout and backpack
- Mission end flow in v0 uses automatic backpack deposit to Town Chest after successful extract/survival.
- Item stats remain data-driven; saves store IDs + quantities (and instance IDs only if added later).

## Consequences
- Strong risk/reward loop.
- Town chest enables recovery from death without starting from zero.
- Supports crafting and loot naturally.

## Related ADRs
- [ADR-009-save-schema-v0-player-owned-json-versioned.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-009-save-schema-v0-player-owned-json-versioned.md)
- [ADR-011-hero-death-safe-state-switching-and-party-continuity.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-011-hero-death-safe-state-switching-and-party-continuity.md)
- [ADR-012-town-buildings-and-meta-progression.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-012-town-buildings-and-meta-progression.md)
- [ADR-013-progression-split-town-knowledge-vs-hero-build.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-013-progression-split-town-knowledge-vs-hero-build.md)
