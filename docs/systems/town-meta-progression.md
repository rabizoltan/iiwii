# Town Meta Progression
Category: Progression System
Role: Forward Note
Last updated: 2026-03-16
Last validated: pending

## Purpose
- Define town-bound persistent progression only.
- This doc covers buildings, resources, and town capability growth.
- Hero-bound XP and weapon mastery are defined in separate progression docs.
- Use ADRs for the authoritative permadeath and progression-split rules.

## Core Rules
- Town progression is **persistent** across runs and hero deaths.
- Town resources/materials are **persistent**.
- Weapon skill knowledge unlocks persist in the town.
- Hero death and gear-loss consequences are defined elsewhere; this doc only describes what the town retains.

## Buildings (v0 set)
Buildings can be extended later without breaking saves.

### Blacksmith
- Function: craft weapons and armor via recipes.
- Progression: building level unlocks additional recipes or tiers.
- Save stores:
  - blacksmith level
  - unlocked recipe IDs

### Alchemist
- Function: craft potions/consumables via recipes.
- Progression: level unlocks additional recipes or tiers.
- Save stores:
  - alchemist level
  - unlocked recipe IDs

### Barracks
- Function: increases roster capacity (max heroes).
- Model: **roster slots only** (simple).
- Save stores:
  - barracks level
  - derived roster capacity (or store capacity directly)

Optional future direction:
- optional recruit pool / recruit quality system (requires new ADR if introduced)

### Kitchen
- Function: craft food buffs/consumables for adventures.
- Progression: level unlocks recipes or increases prep capacity.
- Save stores:
  - kitchen level
  - unlocked recipe IDs

### Storage / Stash (implicit town capability)
- Function: persistent resources and optional items storage.
- Save stores:
  - town resources (gold/materials)
  - optional stored items (IDs + quantities)

## Town Resources
Town resources are a persistent inventory used for crafting and upgrades.
Examples:
- gold
- ore/metal
- herbs
- scrap

## Crafting And Upgrades
- Recipes are defined in config data files (not in save).
- Save stores only:
  - recipe IDs unlocked
  - building levels
  - resource quantities
- Upgrades consume town resources and permanently increase town capability.

## Minimum For VS-001
For vertical slice, it is enough to support:
- persistent resource counter(s)
- one building level (e.g., blacksmith level 1)
- one craftable item (placeholder)
- writing these changes to the local save at mission end

## What This Doc Does Not Cover
- Hero XP and talent point allocation
- Weapon-type XP tracking
- Combat rules
- Full hero death handling or inventory-loss rules
