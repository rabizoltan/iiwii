# Player / Hero Progression (Character XP + Talents)

## Purpose
- Define hero-bound progression only.
- This doc covers character XP, level, and talent allocation on a hero.
- Town-bound knowledge and town systems are documented elsewhere.

## Hero Progression Loop
- Hero earns **Character XP** from missions (kills, objectives, extraction).
- Character XP increases **Hero Level**.
- Each level grants **Talent Points**.
- Talent Points are spent in class talent trees.
- Talents modify how the hero plays.

## What Is Saved (hero-bound)
Per hero:
- `character_xp`
- `level`
- `unspent_talent_points`
- `talents_spent` (talent_id -> rank)

## Death Rule
If a hero dies:
- the hero becomes `status = dead`
- all hero-bound progression is lost for future play (cannot be selected)
- town-bound unlocks remain (weapon knowledge + buildings/resources)

Default mode:
- Hero permadeath is ON.

Optional mode:
- A non-permadeath setting may be offered later for players who do not want permanent hero death.
- Even in that mode, town-bound progression remains persistent as usual.

## What This Doc Does Not Cover
- Weapon mastery persistence
- Town buildings and town resources
- Inventory/loadout persistence
- Detailed class design beyond hero talent allocation

## Design Constraints
- Save stores only IDs and ranks, not computed stats.
- Talent definitions and effects live in config files (data-driven).
- Talents should be designed so a fresh hero is viable even with only town knowledge unlocked.
