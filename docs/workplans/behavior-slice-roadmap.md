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
- Slice 1 - Player attack behavior: `completed`
- Slice 2 - Debug control panel: `completed`
- Slice 3 - Enemy close-range behavior: `active`
- Slice 4 - Combat feedback and debug behavior: `blocked`

## Recommended Order
1. Player attack behavior
2. Debug control panel
3. Enemy close-range behavior
4. Combat feedback and debug behavior

## Current Planned Sequence
1. Start with [player-attack-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/player-attack-behavior-slice.md)
2. Add [debug-control-panel-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/debug-control-panel-slice.md) so current and follow-up behavior slices share the same runtime debug controls
3. After player attack and debug control are validated, continue with [enemy-close-range-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/enemy-close-range-behavior-slice.md)
4. After the behavior slices are stable enough, define and execute [combat-feedback-and-debug-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/combat-feedback-and-debug-behavior-slice.md)

Rule:
- do not start the melee close-range behavior slice before the player attack behavior slice is implemented and validated
- do not start the combat feedback/debug slice as a design driver for combat behavior

## Slice 1 - Player Attack Behavior
Status: `completed`

Plan file:
- [player-attack-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/player-attack-behavior-slice.md)

Why first:
- Current attack exists only as a minimal proof.
- Attack direction, cadence, and aiming rules will affect enemy behavior and combat feel.

Current state:
- Mouse/world aiming, no-fire rules, blocker-aware projectile travel, and demo-scene validation are complete.
- This slice is closed and ready for follow-up behavior work.

Execution priority:
- immediate next implementation slice

## Slice 2 - Debug Control Panel
Status: `completed`

Plan file:
- [debug-control-panel-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/debug-control-panel-slice.md)

Why second:
- Shared runtime debug controls improve validation for both player attack and enemy behavior work.

Current state:
- The `F3` debug menu and first shared toggles are implemented and validated.
- This slice is closed and available for follow-up behavior work.

Execution priority:
- immediate follow-up to player attack validation support

## Slice 3 - Enemy Close-Range Behavior
Status: `active`

Plan file:
- [enemy-close-range-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/enemy-close-range-behavior-slice.md)

Why second:
- Enemy stop distance, spreading, overlap avoidance, and local positioning should be defined against the finalized attack model.

Current state:
- The slice is being rebuilt against the renewed melee behavior contract.
- Current runtime progress includes explicit melee states, approach-goal selection, local close-adjust movement, and distance-envelope melee hold.
- Soft spreading, constrained crowd-yield, and dense-crowd validation are still pending.

Execution priority:
- active

## Slice 4 - Combat Feedback And Debug Behavior
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
