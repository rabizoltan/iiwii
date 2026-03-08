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

### Survival rule
- If the hero **survives/extracts**, they keep everything:
  - their loadout
  - backpack contents (then can deposit to chest)
  - earned resources
- If the hero **dies**, the hero is lost and everything on them is lost:
  - loadout + backpack are lost with the hero
  - town chest, town resources, town buildings, and town knowledge remain

## Implications
- Save must store:
  - town chest contents
  - per-hero loadout and backpack
- Mission end flow in v0 uses automatic backpack deposit to Town Chest after successful extract/survival.
- Item stats remain data-driven; saves store IDs + quantities (and instance IDs only if added later).

## Consequences
- Strong risk/reward loop.
- Town chest enables recovery from death without starting from zero.
- Supports crafting and loot naturally.