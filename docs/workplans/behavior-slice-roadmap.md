# Behavior Slice Roadmap

## Status
- `active`

## Role
- This file is the planning entry point after the first playable foundation slice.
- It defines the next behavior-specific slices that should replace open-ended prototype polishing.
- It does not guess unresolved gameplay details. If a slice requires a design decision, that slice remains `blocked` until specified.

## Why This Exists
- The first playable slice proved the runtime foundation.
- Continuing to "just improve the prototype" would create scope creep.
- The next work should be separated into smaller behavior slices with explicit acceptance criteria.

## Slice Status Board
- Slice 1 - Player attack behavior: `active`
- Slice 2 - Enemy close-range behavior: `active`
- Slice 3 - Combat feedback and debug behavior: `blocked`

## Recommended Order
1. Player attack behavior
2. Enemy close-range behavior
3. Combat feedback and debug behavior

## Current Planned Sequence
1. Start with [player-attack-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/player-attack-behavior-slice.md)
2. After player attack behavior is implemented and validated, continue with [enemy-close-range-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/enemy-close-range-behavior-slice.md)
3. After both behavior slices are stable enough, define and execute [combat-feedback-and-debug-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/combat-feedback-and-debug-behavior-slice.md)

Rule:
- do not start the melee close-range behavior slice before the player attack behavior slice is implemented and validated
- do not start the combat feedback/debug slice as a design driver for combat behavior

## Slice 1 - Player Attack Behavior
Status: `active`

Plan file:
- [player-attack-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/player-attack-behavior-slice.md)

Why first:
- Current attack exists only as a minimal proof.
- Attack direction, cadence, and aiming rules will affect enemy behavior and combat feel.

Current state:
- Core attack behavior is now specified enough to proceed.
- Only tuning values and fallback edge cases remain open.

Execution priority:
- immediate next implementation slice

## Slice 2 - Enemy Close-Range Behavior
Status: `active`

Plan file:
- [enemy-close-range-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/enemy-close-range-behavior-slice.md)

Why second:
- Enemy stop distance, spreading, overlap avoidance, and local positioning should be defined against the finalized attack model.

Current state:
- Baseline melee close-range behavior is now specified enough to proceed.
- Follow-up tuning can happen during implementation without redefining the behavioral rule.

Execution priority:
- start only after the player attack behavior slice is complete enough to validate against

## Slice 3 - Combat Feedback And Debug Behavior
Status: `blocked`

Plan file:
- [combat-feedback-and-debug-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/combat-feedback-and-debug-behavior-slice.md)

Why third:
- It should be built on top of the chosen combat and enemy behavior rules.

Blocker:
- Feedback/debug requirements need explicit scope decisions before implementation should continue.

## Rule For Next Work
- Do not reopen the foundation slice for behavior tuning.
- Start the next implementation only from a behavior slice with explicit success criteria.
