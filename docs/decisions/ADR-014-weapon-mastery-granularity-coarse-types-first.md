# ADR-014: Weapon Mastery Granularity (Coarse Types First)

## Status
Accepted

## Context
Weapon mastery affects saves, UI, balancing, and content authoring. Early over-granularity increases complexity and rework risk.

## Decision
Weapon mastery will use **coarse weapon types** in v0 (broad setups like 2H vs 1H+Shield vs Dual Wield).
Weapon family distinctions (sword/axe/mace) are cosmetic/weapon-stat differences only and do not create separate mastery tracks in v0.

## Consequences
- Faster implementation and easier balancing.
- If we later split mastery by weapon family, we must introduce a new ADR and save migration.
