# Talents and Perks

## Intent
- Define only the persistence and ownership boundaries for talents and perks.
- Detailed tree layout and specific node content belong elsewhere.
- Use ADRs and the narrower progression docs for the authoritative progression split.

## Ownership Split
- Hero talent allocation is hero-bound.
- Town perk and knowledge unlocks are town-bound.
- Equipped perk configuration is saved as a profile-level preset if that system is implemented.

## Balance Guidelines
- Prioritize playstyle shifts over flat multipliers.
- Avoid must-pick nodes by keeping branch value comparable.
- Co-op utility perks should compete with selfish DPS picks.

## Persistence
- Hero talent point allocation is hero-bound and is lost when that hero dies.
- Town-level perk and knowledge unlocks are persistent and survive hero death.
- Equipped configuration is saved in player profile presets.

## Current Scope Note
- The current milestone does not need full perk-system implementation.
- If a task only needs hero XP, talent points, or weapon mastery, prefer the narrower progression docs instead.
