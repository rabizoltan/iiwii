# Player / Hero Progression (Character XP + Talents)
Category: Progression System
Role: Reference Contract
Last updated: 2026-03-16
Last validated: pending

## Purpose
- Define hero-bound progression only.
- This doc covers character XP, level, and talent allocation on a hero.
- Town-bound knowledge and town systems are documented elsewhere.
- Use the ADR layer for the authoritative permadeath rule.

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

## What This Doc Does Not Cover
- Weapon mastery persistence
- Town buildings and town resources
- Inventory/loadout persistence
- Detailed class design beyond hero talent allocation
- Full death-flow handling; see [ADR-011-hero-death-safe-state-switching-and-party-continuity.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-011-hero-death-safe-state-switching-and-party-continuity.md)

## Design Constraints
- Save stores only IDs and ranks, not computed stats.
- Talent definitions and effects live in config files (data-driven).
- Talents should be designed so a fresh hero is viable even with only town knowledge unlocked.
