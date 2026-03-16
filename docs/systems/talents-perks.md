# Talents and Perks
Category: Progression System
Role: Forward Note
Last updated: 2026-03-16
Last validated: pending

## Intent
- Define only the persistence and ownership boundaries for talents and perks.
- Detailed tree layout and specific node content belong elsewhere.
- Use ADRs and the narrower progression docs for the authoritative progression split.

## Ownership Split
- Hero talent allocation is hero-bound.
- Town perk and knowledge unlocks are town-bound.
- Equipped perk configuration, if added later, should follow player-owned persistence rules.

## Balance Guidelines
- Prioritize playstyle shifts over flat multipliers.
- Avoid must-pick nodes by keeping branch value comparable.
- Co-op utility perks should compete with selfish DPS picks.

## Persistence
- Hero talent point allocation is hero-bound and is lost when that hero dies.
- Town-level perk and knowledge unlocks are persistent and survive hero death.
- Any later preset system should remain player-owned rather than hero-owned.

## Current Scope Note
- The current milestone does not need full perk-system implementation.
- If a task only needs hero XP, talent points, or weapon mastery, prefer the narrower progression docs instead.
