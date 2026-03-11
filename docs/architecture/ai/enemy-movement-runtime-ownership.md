# Enemy Movement Runtime Ownership

## Purpose
- Record the current implementation ownership after the enemy movement refactor.
- Keep the runtime boundaries explicit before deeper behavior changes begin.

## Current Ownership
- `enemy_controller.gd`
  - Scene-facing enemy runtime shell.
  - Physics tick entry, target resolution, scene node wiring, HP/death, and debug/profiling integration.
  - Runs the enemy physics tick in explicit phases: step preparation, horizontal movement dispatch, vertical velocity update, and final movement/debug/stuck handling.
  - Coordinates movement helpers and applies horizontal movement/facing results.
  - Those grouped controller-side runtime states are now explicit typed objects rather than ad hoc dictionaries.
- `enemy_close_state.gd`
  - Close-range state classification and naming.
  - Owns the `approach -> close_adjust -> melee_hold` envelope logic.
- `enemy_movement_state_machine.gd`
  - Owns movement-state transition evaluation and state dispatch sequencing.
  - Keeps the controller out of direct `match`-based movement state orchestration.
  - Its controller-facing transition and dispatch APIs now use typed request/result objects instead of flattened dictionaries.
- `enemy_goal_selector.gd`
  - Melee engage-goal sampling, nav projection, spread-aware candidate scoring, failed-goal exclusion, and bounded path-length tiebreak.
  - Its controller-facing selection API now uses typed request/result objects instead of a flattened dictionary payload.
- `enemy_crowd_response.gd`
  - Close-adjust lateral bias, hold-time yield behavior, crowd-pressure estimation, and player-push resolution.
  - Its main controller-facing close-adjust, yield, and player-push resolution APIs now use typed request/result objects instead of flattened dictionary payloads.
- `enemy_navigation_locomotion.gd`
  - Navigation cache refresh policy, nav refresh interval selection, next-path-point resolution, and approach movement shaping.
  - Its controller-facing cache/interval/approach APIs now use typed request/result objects instead of flattened dictionary payloads.
- `enemy_crowd_query.gd`
  - Shared enemy registry ownership, spread-query filtering, and short-lived local-neighbor cache policy for crowd-aware movement decisions.
- `enemy_movement_influence.gd`
  - External movement influence intake and application.
  - Currently formalizes player-push accumulation/decay so external pressure is no longer a special-case velocity path embedded directly in the controller.
  - Its controller-facing queue/apply APIs now use typed request/result objects instead of flattened dictionaries.
- `enemy_debug_telemetry.gd`
  - Enemy debug label presentation, nav-path visualization, debug log writing, melee-hold log writing, and shared enemy profiling accumulators.
  - Goal-path debug capture now also uses a typed transport object instead of a small dictionary seam.
- `enemy_debug_snapshot.gd`
  - Typed telemetry transport object passed from the enemy controller into telemetry, replacing the previous flattened debug snapshot dictionary boundary.
- `enemy_debug_snapshot_builder.gd`
  - Owns typed debug snapshot assembly from controller/runtime state into `enemy_debug_snapshot.gd`.
  - Keeps telemetry payload construction out of the main enemy controller flow.

## Important Boundary
- Baseline locomotion-driven player push has been removed from `player_controller.gd`.
- Enemy movement still retains the generic external movement-influence interface, with the old player-push compatibility wrapper still present on the enemy side.
- The remaining behavior work for this slice is to narrow practical influence usage to authored combat displacement and explicit escape/crowd-pressure rules.

## Next Refactor Target
- Reduce the remaining small untyped helper internals into typed request/response objects where the added structure still pays for itself.
- The main remaining candidates are internal dictionary-heavy helper paths inside `enemy_crowd_response.gd`, the path-tiebreak candidate plumbing in `enemy_goal_selector.gd`, and the callable-based dispatch tradeoff in `enemy_movement_state_machine.gd`.

## Next Behavior Target
- Execute the player-enemy collision and crowd-pressure slice.
- Remove baseline player walk-push behavior.
- Add a short explicit player escape ghosting state.
- Re-scope external movement influence to combat-authored displacement.
- Introduce a limited active melee front line near the player so dense packs stay readable and cheaper.
