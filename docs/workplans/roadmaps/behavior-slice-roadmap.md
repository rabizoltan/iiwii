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
- Slice 3 - Enemy close-range behavior: `completed`
- Slice 4 - Player-enemy collision and crowd pressure: `stable-baseline`
- Slice 5 - Combat feedback and debug behavior: `parked`
- Slice 6 - Player mobility foundation: `completed`
- Slice 7 - Player vault traversal: `completed`
- Future Planning - Remaining traversal slices: `planned`

## Recommended Order
1. Player attack behavior
2. Debug control panel
3. Enemy close-range behavior
4. Player-enemy collision and crowd pressure
5. Combat feedback and debug behavior only if explicitly reopened later
6. Player mobility foundation
7. Player vault traversal
8. Vault follow-up traversal slices such as crouch or mantle after explicit scope selection

## Current Planned Sequence
1. Start with [player-attack-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/completed/player-attack-behavior-slice.md)
2. Add [debug-control-panel-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/completed/debug-control-panel-slice.md) so current and follow-up behavior slices share the same runtime debug controls
3. After player attack and debug control are validated, continue with the historical slice note at [enemy-close-range-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/stale/enemy-close-range-behavior-slice.md) while treating [enemy-melee-behavior-v1.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/ai/enemy-melee-behavior-v1.md) as the current behavior source of truth
4. After close-range enemy behavior is stable enough, execute [player-enemy-collision-and-crowd-pressure-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/completed/player-enemy-collision-and-crowd-pressure-slice.md)
5. If combat feedback becomes a priority later, rescope from [combat-feedback-and-debug-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/stale/combat-feedback-and-debug-behavior-slice.md) instead of treating it as an active plan
6. The first traversal follow-up is complete at [player-mobility-foundation-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/completed/player-mobility-foundation-slice.md)
7. Vault traversal is now closed at [player-vault-traversal-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/completed/player-vault-traversal-slice.md)
8. Future mantle or climb-up work now has its own separate planning document at [player-mantle-climb-up-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/planned/player-mantle-climb-up-slice.md)

Rule:
- do not start the melee close-range behavior slice before the player attack behavior slice is implemented and validated
- do not start the combat feedback/debug slice as a design driver for combat behavior
- do not reopen melee-navigation follow-up work implicitly; treat the current baseline as closed unless a new explicit scope is chosen

## Slice 1 - Player Attack Behavior
Status: `completed`

Plan file:
- [player-attack-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/completed/player-attack-behavior-slice.md)

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
- [debug-control-panel-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/completed/debug-control-panel-slice.md)

Why second:
- Shared runtime debug controls improve validation for both player attack and enemy behavior work.

Current state:
- The `F3` debug menu and first shared toggles are implemented and validated.
- This slice is closed and available for follow-up behavior work.

Execution priority:
- immediate follow-up to player attack validation support

## Slice 3 - Enemy Close-Range Behavior
Status: `completed`

Plan file:
- [enemy-close-range-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/stale/enemy-close-range-behavior-slice.md)

Why second:
- Enemy stop distance, spreading, overlap avoidance, and local positioning should be defined against the finalized attack model.

Current state:
- Engage-point movement, hold/facing behavior, soft spreading, physical crowd collision, constrained crowd-yield, and profiling support are implemented and manually validated in the demo scene.
- This slice is closed for the current milestone and superseded as a source of truth by the architecture docs.
- No further melee-navigation refinement slice is planned right now.

Execution priority:
- completed

## Slice 4 - Player-Enemy Collision And Crowd Pressure
Status: `stable-baseline`

Plan file:
- [player-enemy-collision-and-crowd-pressure-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/completed/player-enemy-collision-and-crowd-pressure-slice.md)

Why next:
- The current dense-pack pressure model still carries prototype-era baseline player push behavior.
- The next gameplay and performance win is to replace that with explicit escape movement and clearer front-line crowd pressure rules.

Current state:
- Enemy close-range behavior and profiling infrastructure exist.
- Baseline locomotion-driven player push has been removed and validated.
- The accepted current baseline keeps only soft ordinary body contact with no old shove/query/assist pipeline activity.
- The current baseline also includes a limited active melee front line near the player.
- This slice has reached a stable return point for the current milestone.

Execution priority:
- no immediate implementation follow-up; future work belongs to traversal and combat slices

## Slice 5 - Combat Feedback And Debug Behavior
Status: `parked`

Plan file:
- [combat-feedback-and-debug-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/stale/combat-feedback-and-debug-behavior-slice.md)

Why third:
- It should be built on top of the chosen combat and enemy behavior rules.

Why parked:
- Feedback/debug requirements need explicit scope decisions before implementation should continue.
- It should not be treated as the automatic next step after the current navigation baseline.

Current dependency state:
- The shared debug menu exists and is usable.
- Enemy close-range movement and crowd-pressure baselines are stable enough to build feedback rules on top of them.
- What remains unresolved is product scope, not runtime plumbing.

## Slice 6 - Player Mobility Foundation
Status: `completed`

Plan file:
- [player-mobility-foundation-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/completed/player-mobility-foundation-slice.md)

Why here:
- It turned the deferred crowd-pressure escape requirement into a concrete shared traversal baseline.

Current state:
- `Shift` now drives a shared mobility runtime with tunable `dodge` and `dash` profiles.
- Dense enemy packs can be escaped through temporary enemy-body ghosting during mobility travel.
- The slice is closed; future traversal work should build on this baseline rather than reopening it casually.

Execution priority:
- completed

## Slice 7 - Player Vault Traversal
Status: `completed`

Plan file:
- [player-vault-traversal-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/completed/player-vault-traversal-slice.md)

Why here:
- It is the next highest-value traversal slice after mobility because it adds low obstacle traversal without mixing in climb-up behavior.

Current state:
- The design boundary and runtime implementation are now complete: vault crosses low authored obstacles and returns to roughly the same floor level.
- Mantle or climb-up remains a separate later slice.
- Implementation is landed and validated manually in DemoMain fixtures.

Execution priority:
- completed

## Future Planning - Remaining Traversal Slices
Status: `planned`

Plan file:
- [player-traversal-and-movement-slice-roadmap.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/roadmaps/player-traversal-and-movement-slice-roadmap.md)

Why separate:
- Vault, crouch, and mantle still affect collision, input priority, combat flow, and traversal geometry in different ways.
- They should not be mixed into one catch-all traversal pass.

Current state:
- The movement spec now includes a real shared dodge/dash mobility foundation.
- Vault is now completed.
- Crouch and mantle remain unimplemented follow-up slices.

Recommendation:
- Treat vault, crouch, and mantle as separate explicit slices under the shared traversal roadmap.

## Rule For Next Work
- Do not reopen the completed mobility foundation slice for casual tuning.
- Do not reopen melee-navigation refinement implicitly.
- Start the next implementation only from a newly chosen slice with explicit success criteria.
