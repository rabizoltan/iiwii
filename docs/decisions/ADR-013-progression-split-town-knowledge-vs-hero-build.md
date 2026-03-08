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

## Consequences
- New heroes start with:
  - weapon XP = 0 for all weapon types
  - access to town-unlocked weapon skills
  - no talents (fresh build)
- Town progression meaningfully reduces "restart pain" without removing permadeath stakes.
