# ADR-013: Progression Split - Town Knowledge vs Hero Build

## Status
Accepted

## Context
iiWii uses permadeath heroes and a persistent town. We need progression that:
- preserves the "new hero" loop (death matters)
- avoids making players start from zero every time
- supports build variety across heroes

## Decision
Progression is split into two tracks:

### Town-bound (persistent)
- Weapon-type skill unlocks ("knowledge") are saved to the town.
- Town buildings/upgrades and resources persist.
- These benefits apply to future heroes.

### Hero-bound (permadeath)
- Character XP / level
- Talent points and talent tree choices
- Weapon XP progress toward thresholds
- Equipped gear / inventory carried by the hero

On hero death:
- Hero-bound progression is lost (hero is dead).
- Town-bound progression remains.

Default rule:
- Permadeath is ON.

Optional future rule:
- A non-permadeath mode may be offered later.
- That option does not change the split between hero-bound and town-bound progression.

## Scope
- This ADR defines the conceptual split between hero-bound and town-bound progression.
- It does not define the exact save schema shape.
- It does not replace the separate ADRs for town systems, hero death flow, or inventory model.

## Consequences
- New heroes start with:
  - weapon XP = 0 for all weapon types
  - access to town-unlocked weapon skills
  - no talents (fresh build)
- Town progression meaningfully reduces "restart pain" without removing permadeath stakes.

## Related ADRs
- [ADR-003-progression-ownership.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-003-progression-ownership.md)
- [ADR-011-hero-death-safe-state-switching-and-party-continuity.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-011-hero-death-safe-state-switching-and-party-continuity.md)
- [ADR-012-town-buildings-and-meta-progression.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-012-town-buildings-and-meta-progression.md)
- [ADR-014-weapon-mastery-granularity-coarse-types-first.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-014-weapon-mastery-granularity-coarse-types-first.md)
- [ADR-015-inventory-model-loadout-backpack-town-chest.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-015-inventory-model-loadout-backpack-town-chest.md)
