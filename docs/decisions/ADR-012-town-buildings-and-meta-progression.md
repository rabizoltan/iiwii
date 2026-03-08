# ADR-012: Town Buildings & Meta Progression (Roster Slots + Persistent Resources)

## Status
Accepted

## Context
iiWii uses:
- permadeath heroes
- player-owned progression and saves
- town as the persistent meta progression hub

We need town progression that:
- gives long-term growth without removing the "new hero" loop
- avoids save-file complexity and future rework
- supports crafting and preparation for missions

## Decision
The Town is a persistent meta progression layer with buildings that unlock options and capacity.

### Town persistence
- Town upgrades and building levels are permanent.
- Town resources/materials are permanent (persist across hero deaths).
- Heroes are permadeath: when a hero dies, their equipped gear is lost.

Default rule:
- Permadeath is ON.

Optional future rule:
- A non-permadeath mode may be offered later.
- That option does not change the persistence rules of town resources, buildings, or town knowledge.

### Buildings (initial set; extensible)
- **Blacksmith**: unlock/craft weapons and armor via recipes.
- **Alchemist**: unlock/craft potions/consumables via recipes.
- **Barracks**: increases **roster slots** (max number of heroes the player can have).
  - Barracks is **roster slots only** in the initial design.
  - Future expansion (not now): recruit quality / recruit pool mechanics may be added later.
- **Kitchen**: prepares food buffs/consumables for adventures via recipes.
- **Storage/Stash** (implicit): persistent town resources and optional stored items.

### Gear persistence rule
- Gear is **hero-bound**.
- If a hero dies, all equipped gear on that hero is lost.
- Town resources remain, enabling crafting a new set for the next hero.

## Implications
- Save files store building levels, unlocked recipe IDs, town resources, and roster size.
- Item stats and crafting costs are defined in data/config files, not in saves.
- Crafting flow becomes a core part of "back to town" loop after mission end.

## Consequences
- Players feel permanent progress through town growth and knowledge unlocks.
- Death remains meaningful (lose hero + their gear), while town persistence reduces frustration.
