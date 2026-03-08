# Inventory System (Loadout, Backpack, Town Chest)

## Scope Note
- This is a later-phase system doc.
- Inventory is not a primary focus of the current movement and enemy-navigation milestone.

## Core Concepts
### Items
Items are referenced by stable IDs (e.g., `w_pistol`, `a_leather_vest`, `c_small_potion`).
Item definitions (stats, costs, effects) live in config data files, not in the save.

### Quantities
- Stackable items (consumables, resources, ammo) use quantities.
- Non-stackable items (weapons, armor) can be stored as single entries by ID in v0.

## Inventory Layers
### Loadout (per hero)
Equipped gear slots (initial):
- `weapon_primary`
- `weapon_secondary` (optional)
- `armor_body`
- consumable quick slots (optional)

### Backpack (per hero)
- Contains loot picked during a mission: items and resources.
- May have capacity rules later; v0 can be unlimited or a simple slot cap.

### Town Chest (per player)
- Persistent storage of items/resources.
- Used to equip heroes before a mission.
- Used as a sink/source for crafting output.

## Mission End Flow
### Extract/survive
- Hero remains alive.
- In v0, backpack contents are auto-deposited to Town Chest (no manual deposit UI).

### Death
- Hero becomes dead.
- Loadout and backpack are lost.
- Town Chest remains unchanged.

## Save Responsibilities (v0)
Town:
- `town.chest.items` (item_id -> quantity)
- `town.resources` (optional separate bucket; can be part of chest)

Hero:
- `hero.loadout.equipment`
- `hero.backpack.items` (item_id -> quantity)
- `hero.backpack.resources` (optional; can be merged into items)

## Optional Future Extensions
- Item instances + randomized modifiers (requires instance IDs)
- Weight/slot capacity and encumbrance
- Auto-sort, stack rules, crafting ingredients handling
