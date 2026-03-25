# Enemy Navigation And Movement Performance Optimization Slice

## Status
- `active`

## Purpose
- Track the narrow enemy navigation and movement performance pass.
- Keep the agreed optimization order in one place.
- Preserve a restart-safe execution plan so the work can resume cleanly later.

## Scope
- Enemy goal-selection cost in dense scenes.
- Enemy refresh timing cost in dense scenes.
- Local crowd-query reuse in close-range movement.
- Close-range steering cost cleanup that preserves current melee behavior.

## Out Of Scope
- New enemy archetypes.
- Combat feedback presentation work.
- Traversal or dodge work.
- Broad AI redesign outside the enemy movement stack.
- Melee behavior redesign unless a later slice explicitly requires it.

## Current Context
1. The broader implementation attempts were rolled back.
2. The current code baseline only keeps the agreed nav-refresh behavior changes:
   - `nav_refresh_far_distance = 3.0`
   - `nav_refresh_interval_near = 0.1`
   - `nav_refresh_interval_far = 0.5`
   - no forced per-frame `APPROACH` refresh
   - continuous movement preserved while using slower refresh timing
3. This workplan is for reintroducing the performance work again in small slices.
4. Each slice should remain independently revertable.

## Recommended Order
1. Goal-selection tuning
2. Frame-staggering
3. Crowd-query reuse
4. Close-range steering cost pass

## Slice 1
### Goal-selection tuning

Purpose:
- reduce the cost of engage-goal selection before touching broader timing logic

Files:
- `godot/scripts/enemy/enemy_controller.gd`
- `godot/scripts/enemy/movement/enemy_goal_selector.gd`
- `godot/scripts/enemy/movement/enemy_runtime_policy.gd` if goal refresh cadence needs a small gate

Likely levers:
- `goal_select_min_interval`
- `goal_commit_duration`
- `engage_candidate_count`
- `goal_path_tiebreak_candidate_count`
- `goal_path_tiebreak_enemy_count_soft_limit`
- `_should_refresh_goal()`
- `_select_engage_goal()`
- `EnemyGoalSelector.select_engage_goal()`

Acceptance checks:
- no visible dumb enemy clustering
- no obvious loss of surround quality
- same dense-crowd scene shows lower spikes
- enemies still reacquire the player cleanly after movement

Risk:
- too much reduction here can make ring distribution visibly worse

## Slice 2
### Frame-stagger heavy updates

Purpose:
- spread expensive updates over time so 40-80 enemies do not refresh on the same frame

Files:
- `godot/scripts/enemy/enemy_controller.gd`
- `godot/scripts/enemy/movement/enemy_runtime_policy.gd`
- `godot/scripts/enemy/movement/enemy_crowd_query.gd`

Likely levers:
- per-enemy randomized initial offsets
- separate cooldown phases for:
  - goal refresh
  - nav refresh
  - local enemy cache refresh

Acceptance checks:
- frame spikes flatten out
- enemy behavior still looks continuous
- no visible synchronized pauses or bursts

Risk:
- can make timing logic harder to read if overdone

## Slice 3
### Crowd-query reuse

Purpose:
- reduce repeated neighbor collection in dense packs

Files:
- `godot/scripts/enemy/movement/enemy_crowd_query.gd`
- `godot/scripts/enemy/enemy_controller.gd`
- `godot/scripts/enemy/movement/enemy_crowd_response.gd`

Likely levers:
- reuse one cached local-neighbor result for multiple close-range calculations
- avoid multiple near-identical radius queries in the same useful window
- only query neighbors in states that actually need them

Acceptance checks:
- dense packs look the same
- fewer repeated local queries on the hot path
- no stale-feeling crowd reactions

Risk:
- too-aggressive reuse can make local steering feel delayed

## Slice 4
### Close-range steering cost pass

Purpose:
- keep close-adjust and yield behavior, but remove unnecessary repeated work

Files:
- `godot/scripts/enemy/movement/enemy_crowd_response.gd`
- `godot/scripts/enemy/enemy_controller.gd`

Likely levers:
- avoid recomputing crowd-pressure inputs more than needed
- reduce redundant side/probe evaluation when state is already stable
- keep the same visible behavior unless a query clearly has low value

Acceptance checks:
- no new jitter
- no obvious change in melee feel
- measurable reduction in close-range overhead

Risk:
- easiest slice to accidentally change gameplay feel, so keep it last

## Best First Implementation Slice
- Slice 1: goal-selection tuning

## Restart Notes
1. Start from the current nav-refresh baseline before reintroducing any later optimization slices.
2. Validate each slice in the same dense-crowd scenario before moving to the next one.
3. If a slice harms behavior quality, revert that slice only and keep the earlier validated slices.
4. Corner and wall-adjacent goal selection should be checked immediately after any goal-selection tuning.

## Progress Tracker
- [ ] Slice 1 started
- [ ] Slice 1 validated
- [ ] Slice 2 started
- [ ] Slice 2 validated
- [ ] Slice 3 started
- [ ] Slice 3 validated
- [ ] Slice 4 started
- [ ] Slice 4 validated
