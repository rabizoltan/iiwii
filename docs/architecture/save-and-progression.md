# Save and Progression

## Purpose
- Define ownership and writeback rules for progression.
- Keep this doc at the architecture level, not as a detailed save-schema specification.
- Use ADRs and system docs for exact permadeath and progression-split rules.

## Ownership Model
- Progression is player-owned and stored per local profile.
- There is no shared town save across party members.
- Hero death outcomes and the hero-bound vs town-bound split are defined in the ADR layer and system docs.

## Persisted Domains
- Account-level currencies and materials.
- Town-level persistent progression domains such as weapon knowledge and town upgrades.
- Hero-bound progression domains such as hero XP, talents, and weapon XP.
- Meta progression flags such as unlocked mission tiers.

## Current Scope
- Detailed save schema design is intentionally deferred.
- Current milestone focus is hero movement, enemy movement, combat feel, and core runtime foundations.
- Save structure should stay minimal until those foundations are stable.

## Mission Resolution Contract
- Current phase: mission outcome is resolved locally and applied to the local profile.
- Multiplayer target: host produces authoritative mission results and each client applies only its own progression delta locally.
- Save write should be transactional or rollback-safe when persistence work becomes real.

## Data Integrity
- Version save data when schema work becomes concrete.
- Validate mission results before applying progression updates.
- Preserve a recovery path for corrupted or partial writes.
