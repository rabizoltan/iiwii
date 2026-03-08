# Save and Progression

## Purpose
- Define ownership and writeback rules for progression.
- Keep this doc at the architecture level, not as a detailed save-schema specification.

## Ownership Model
- Progression is player-owned and stored per local profile.
- There is no shared town save across party members.
- Town-bound progression persists across hero death.
- Hero-bound progression follows the permadeath rules defined elsewhere.

## Persisted Domains
- Account-level currencies and materials.
- Town-level highest weapon XP per type and unlocked weapon knowledge.
- Hero talent allocations and other hero-bound progression.
- Meta progression flags such as town upgrades and unlocked mission tiers.

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
