# Enemy Movement Runtime Ownership
Category: Runtime Architecture
Role: Runtime Truth
Last updated: 2026-03-17
Last validated: 2026-03-17

## Purpose
- Record the current implementation ownership after the enemy movement refactor.
- Keep the runtime boundaries explicit before deeper behavior changes begin.

## Current Ownership
- `enemy_controller.gd`
  - Scene-facing enemy runtime shell.
  - Physics tick entry, target resolution, scene node wiring, HP/death, and debug/profiling integration.
  - Runs the enemy physics tick in explicit phases: step preparation, horizontal movement dispatch, vertical velocity update, and final movement/debug/stuck handling.
  - Coordinates movement helpers, applies horizontal movement/facing results, and assembles the minimal nav-debug snapshot used by the `F3` overlay.
- `enemy_close_state.gd`
  - Close-range state classification and naming.
  - Owns the `approach -> close_adjust -> melee_hold` envelope logic.
- `enemy_movement_state_machine.gd`
  - Owns movement-state transition evaluation for `approach`, `close_adjust`, and `melee_hold`.
  - Its controller-facing transition API uses typed request/result objects instead of flattened dictionaries.
- `enemy_goal_selector.gd`
  - Melee engage-goal sampling, nav projection, spread-aware candidate scoring, failed-goal exclusion, and bounded path-length tiebreak.
  - Its controller-facing selection API now uses typed request/result objects instead of a flattened dictionary payload.
- `enemy_runtime_policy.gd`
  - Owns goal-lifetime and nav-cache policy that used to live directly in the controller.
  - Tracks goal commit/cooldown timers, failed-goal memory, nav-cache lifetime, cache invalidation, and the request/response seams for goal refresh and cached next-position reuse.
- `enemy_crowd_response.gd`
  - Close-adjust lateral bias, hold-time yield behavior, crowd-pressure estimation, and player-push resolution.
  - Its main controller-facing close-adjust, yield, and player-push resolution APIs now use typed request/result objects instead of flattened dictionary payloads.
- `enemy_navigation_locomotion.gd`
  - Nav refresh heuristics, refresh interval selection, next-path-point resolution, and approach movement shaping.
  - Its cache/interval helpers are now consumed through `enemy_runtime_policy.gd`, while approach movement shaping is still called directly by the controller.
- `enemy_crowd_query.gd`
  - Shared enemy registry ownership, spread-query filtering, and short-lived local-neighbor cache policy for crowd-aware movement decisions.
- `enemy_movement_influence.gd`
  - External movement influence intake and application.
  - Currently formalizes authored external displacement accumulation/decay so external forces are no longer a special-case velocity path embedded directly in the controller.
  - Its controller-facing queue/apply APIs now use typed request/result objects instead of flattened dictionaries.
- `enemy_runtime_state.gd`
  - Typed runtime state containers for goal debug candidate storage and movement influence state.
  - Keeps the remaining shared transient state small after the debug cleanup removed unused hold/yield/close-adjust debug payloads.
- `enemy_debug_telemetry.gd`
  - Enemy nav-path visualization controlled by the `F3` overlay and shared enemy profiling accumulators.
- `enemy_debug_snapshot.gd`
  - Minimal typed transport object passed from the enemy controller into telemetry for current path, current goal, and candidate ring data.
- `enemy_debug_snapshot_builder.gd`
  - Owns the minimal nav-debug snapshot assembly from controller state into `enemy_debug_snapshot.gd`.

## Important Boundary
- Baseline locomotion-driven player push has been removed from `player_controller.gd`.
- Enemy movement retains a generic external movement-influence interface for authored displacement such as combat knockback or shove effects.
- The remaining behavior work for this slice is to narrow practical influence usage to authored combat displacement and explicit escape/crowd-pressure rules.

## Next Refactor Target
- Reduce the remaining small untyped helper internals into typed request/response objects where the added structure still pays for itself.
- The main remaining candidates are internal dictionary-heavy helper paths inside `enemy_crowd_response.gd`, the path-tiebreak candidate plumbing in `enemy_goal_selector.gd`, and the callable-based dispatch tradeoff in `enemy_movement_state_machine.gd`.

## Next Behavior Target
- Execute the player-enemy collision and crowd-pressure slice.
- Add a short explicit player escape ghosting state.
- Re-scope external movement influence to combat-authored displacement.
- Introduce a limited active melee front line near the player so dense packs stay readable and cheaper.
- Baseline player walk-push behavior is already removed; the remaining follow-up work belongs to traversal and combat-authored displacement slices.
