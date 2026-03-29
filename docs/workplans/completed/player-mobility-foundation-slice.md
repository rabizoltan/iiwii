# Player Mobility Foundation Slice

## Status
- `completed`

## Purpose
- Establish a shared player mobility foundation for short dodge and longer dash behavior.
- Keep the first traversal implementation narrow, tunable, and reusable by future class kits.
- Provide the explicit escape movement deferred by the crowd-pressure baseline without mixing in full traversal scope.

## Final Role
- This file is the completed implementation record for the first traversal slice.
- Runtime movement truth now lives in [movement-spec.md](d:/Game/DEV/iiWii/iiwii/docs/systems/movement-spec.md), [code-map.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/code-map.md), and the player runtime in `godot/scripts/player/player_controller.gd`.
- Future traversal follow-up should continue from the roadmap in [player-traversal-and-movement-slice-roadmap.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/roadmaps/player-traversal-and-movement-slice-roadmap.md), not by reopening this slice implicitly.

## Delivered Outcome
1. One shared mobility runtime now exists in the player controller.
2. `Shift` triggers the mobility action through the project input map.
3. The same runtime can be tuned into a short `dodge` or a longer `dash` through exported profile values.
4. Mobility travel temporarily disables regular locomotion and attack execution during the burst.
5. Enemy-body ghosting during mobility provides the explicit dense-pack escape behavior deferred by the crowd-pressure slice.
6. The mobility start frame now applies its first travel step immediately so the dash handoff stays smooth while movement input is already held.

## Scope That Was Intentionally Kept Out
- Blink or teleport behavior.
- Vault implementation.
- Crouch implementation.
- Full class-aware runtime branching.
- Charges, talents, upgrade trees, and authored travel or end effects.

## Acceptance Outcome
1. Pressing `Shift` starts mobility when not blocked by cooldown or lock state. `completed`
2. The runtime supports both short dodge and longer dash tuning without a separate state machine. `completed`
3. The player can escape dense enemy body pressure through the mobility action. `completed`
4. Normal locomotion still does not restore baseline player shove behavior. `completed`
5. Attack input remains locked during travel and resumes afterward. `completed`
6. The slice leaves a clean follow-up path for class-aware specialization and authored effect hooks. `completed`

## Validation Notes
- The implementation was manually validated in the demo scene during development.
- The main gameplay checks covered:
  - `Shift` input activation
  - short dodge profile behavior
  - longer dash profile behavior
  - dense-pack enemy escape
  - cooldown gating
  - attack lockout during travel
  - clean locomotion return after travel ends
  - smooth dash start while already holding movement input
- I did not run automated runtime validation from the terminal environment; final feel confirmation came from in-editor playtesting.

## Follow-Up Candidates
- class-aware mobility profile selection
- authored trail or end effects
- vault slice
- crouch slice
- blink or teleport slice as a separate later design decision
