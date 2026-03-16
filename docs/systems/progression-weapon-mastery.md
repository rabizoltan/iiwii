# Weapon Mastery (Weapon XP + Town Knowledge Unlocks)
Category: Progression System
Role: Forward Note
Last updated: 2026-03-16
Last validated: pending

## Purpose
- Define weapon-type XP and town weapon knowledge.
- This doc does not define general hero XP or town building progression.
- Use the ADR layer for the authoritative hero-bound vs town-bound split.

## Granularity Rule (v0)
For the first versions of the game, mastery tracks broad weapon setups rather than individual weapon families (sword vs axe vs mace).

This reduces complexity and avoids rework in:
- save data
- UI
- balancing
- content authoring

## Weapon Types (v0)
Weapon types are defined per class where needed. Example for Warrior:
- `wt_war_1h_shield`  (one-handed + shield)
- `wt_war_2h`         (two-handed weapon)
- `wt_war_dual_1h`    (dual wield)

Notes:
- The exact weapon item (sword/axe/mace) does not change the mastery type in v0.
- We may split weapon families later with a new ADR + migration (e.g., `wt_war_2h_sword`, `wt_war_2h_axe`).

## Weapon XP (hero-bound)
- Each hero tracks weapon XP per weapon type.
- XP increases by using that weapon type in missions.
- New heroes start at 0 weapon XP for all weapon types.

## Weapon Skills (town-bound knowledge)
- Town stores the highest reached weapon XP per weapon type.
- Weapon-type skill unlocks are evaluated from the town-stored highest XP.
- New heroes start at 0 hero weapon XP, but can learn/use already unlocked town weapon knowledge.

## Mission-End Merge Rule
On successful mission resolution:
- compare `hero.weapon_xp[weapon_type_id]` vs `town.weapon_knowledge.max_weapon_xp_by_type[weapon_type_id]`
- if hero value is higher, update town max XP to that higher value
- re-evaluate unlock thresholds and unlock newly available weapon skills

This means town mastery never decreases, even if a high-XP hero dies later.

## Stored Values
Hero (permadeath):
- `hero.weapon_xp[weapon_type_id] = number`

Town (persistent):
- `town.weapon_knowledge.max_weapon_xp_by_type[weapon_type_id] = number`
- `town.weapon_knowledge.unlocked_skills_by_weapon_type[weapon_type_id] = [skill_ids]`

## What This Doc Does Not Cover
- Hero character XP and talent points
- Town buildings and resources
- Inventory persistence
- Full death handling; see [ADR-011-hero-death-safe-state-switching-and-party-continuity.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-011-hero-death-safe-state-switching-and-party-continuity.md)

## Design Constraints
- Saves store only IDs and numbers, never balance stats.
- Weapon skill definitions live in config files (data-driven).
