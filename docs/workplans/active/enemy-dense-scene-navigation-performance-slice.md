# Enemy Dense-Scene Navigation Performance Slice

## Status
- `active`

## Purpose
- Track the current dense-scene enemy navigation performance pass.
- Keep the revised optimization direction separate from the earlier failed attempt.
- Preserve a clean execution plan focused on measurable runtime-cost reduction without sacrificing readable melee surround behavior.

## Scope
- Goal-selection cost in dense scenes.
- Navigation next-position refresh cost and refresh cadence correctness.
- Registry-wide crowd and rank scan cost.
- Repeated close-range steering cost.

## Out Of Scope
- New enemy archetypes.
- Combat feedback presentation work.
- Traversal or dodge work.
- Broad AI redesign outside the enemy movement stack.
- Replacing melee surround behavior with a fundamentally different combat model.

## Current Direction
1. Keep readable melee surround behavior near the player.
2. Reduce dense-scene pathfinding and crowd-query cost before attempting broader redesign.
3. Make expensive planning work more event-driven.
4. Keep each optimization slice independently revertable.

## Core Planning Rules
- Preserve current melee readability in `DemoMain.tscn`.
- Prefer cheaper decision policy before heavier structural redesign.
- Treat path-query count as the first major cost to reduce.
- Do not keep expensive surround-solving active for far-away enemies.
- Fix timing/caching behavior before adding more timing complexity.

## Slice 1
### Goal-selection cost reduction

Purpose:
- keep ring-based surround behavior where it matters
- reduce path-query volume and unnecessary far-range surround solving

Files:
- `godot/scripts/enemy/enemy_controller.gd`
- `godot/scripts/enemy/movement/enemy_goal_selector.gd`
- `godot/scripts/enemy/movement/enemy_runtime_policy.gd`

Current behavior summary:
- The selector builds a ring of candidate engage points around the player.
- Each candidate is projected to navmesh.
- Recently failed candidates are rejected.
- A soft spread penalty is applied against nearby enemies.
- Path validation and path-length tiebreak logic are then used to choose the final goal.

Why it is expensive:
- `engage_candidate_count` is high enough that one refresh can produce many nav projections and several path queries.
- Path metrics are computed for all valid candidates before the shortlist is narrowed.
- Spread scoring cost grows with local density, so the path cost compounds when many enemies contest the same area.

Agreed near-vs-far rule:
- Enemies farther than about `3.0m` from the player should use a cheaper direct chase goal.
- Ring/surround selection should only matter once the enemy is inside that near-range band.
- For the first implementation pass, direct chase should target the player position through the normal nav-safe movement path rather than a projected engage-distance proxy.

Goal-refresh policy direction:
- Goal refresh should stay event-driven rather than tick-driven.
- Refresh is appropriate when:
- there is no current goal
- the current goal failed or became invalid
- the player moved far enough to make the current goal stale
- the enemy is near its current goal and needs a local reacquire
- the enemy is stuck strongly enough to justify replanning
- Refresh should be avoided when:
- the enemy is still far away and making progress
- the player has not moved meaningfully
- the enemy is temporarily crowd-blocked but the current goal is still acceptable
- the enemy is in recovery or cooldown
- the enemy cannot currently make use of a fresh goal

Likely levers:
- `goal_select_min_interval`
- `goal_commit_duration`
- `goal_reacquire_distance`
- `engage_candidate_count`
- `goal_path_tiebreak_candidate_count`
- `_should_refresh_goal()`
- `_select_engage_goal()`
- `EnemyGoalSelector.select_engage_goal()`

Preferred optimization direction:
- keep the current ring-based behavior style
- reduce candidate count
- use a two-stage selector
- run path queries only for the best cheap-score finalists
- avoid full surround solving for far-away enemies

Acceptance checks:
- no visible dumb clustering near the player
- no obvious loss of surround quality
- enemies still reacquire the player cleanly after movement
- dense-scene spikes improve measurably

Risk:
- over-reducing candidate quality can make surround distribution visibly worse

## Slice 2
### Navigation refresh correctness and cadence

Purpose:
- make nav caching actually suppress expensive next-position refresh work
- only then evaluate stronger stagger or cadence changes

Files:
- `godot/scripts/enemy/enemy_controller.gd`
- `godot/scripts/enemy/movement/enemy_runtime_policy.gd`
- `godot/scripts/enemy/movement/enemy_navigation_locomotion.gd`

Current issue:
- `EnemyRuntimePolicy.get_navigation_next_position()` stores cache timing state, but still calls `resolve_next_position` unconditionally.
- That means refresh timing exists, but expensive next-position work is not truly being skipped.
- This should be treated as an optimization-correctness problem, not just as a tuning problem.

Failed attempt already observed:
- A direct cache of the returned next navigation position was tested and then discarded.
- In-engine result: enemies showed stop-and-go movement instead of continuous path following.
- This failure should remain documented so the same invalid optimization boundary is not retried later.
- A follow-up attempt that throttled `NavigationAgent3D.target_position` refresh while preserving per-frame `get_next_path_position()` was also tested and rejected.
- In-engine result: enemy movement still became noticeably jerky.
- This means Slice 2 is not yet ready for another blind implementation pass; safer observation and narrower diagnosis are needed before retrying.

Why this matters:
- `_refresh_navigation_cache()` currently updates `NavigationAgent3D.target_position`.
- `EnemyNavigationLocomotion.resolve_navigation_next_position()` then pulls fresh navigation data through `get_next_path_position()` and, when needed, `get_current_navigation_path()`.
- If that resolver still runs every time the controller asks for a next position, the near/far refresh intervals do not suppress the expensive part of navigation work.

Godot API constraint confirmed:
- Godot documentation states that after setting `NavigationAgent3D.target_position`, `get_next_path_position()` should be used once every physics frame to update the agent's internal path logic.
- This means the returned next path position is not a safe cross-frame cache target for this slice.
- The safe optimization boundary is target refresh / repath churn, not the per-frame path-follow update call itself.

Planning focus:
- separate "refresh policy exists" from "refresh policy actually avoids work"
- verify how often `_refresh_navigation_cache()` currently runs
- keep continuous `get_next_path_position()` usage intact
- reduce unnecessary `target_position` updates and repath churn before layering on stronger stagger
- keep current near/far refresh tuning only if it starts paying off in practice

Decision taken for this slice:
- Do not add more cadence complexity before the cache actually skips work.
- Do not cache the returned next navigation position across physics frames.
- Keep per-frame path-follow progression continuous.
- Treat target-refresh throttling as unproven and currently rejected until better evidence shows a safe boundary.
- Only after that, measure whether additional staggering is still necessary.

Likely levers:
- conditional target-position refresh
- explicit cache invalidation rules
- per-enemy initial offsets if more staggering is still needed after cache correctness is fixed

Required behavior change:
- Continuous `get_next_path_position()` calls should remain in the physics loop.
- Do not currently assume that suppressing `_nav_agent.target_position = move_target` is safe in this implementation.
- Before another Slice 2 implementation attempt, identify a narrower repath-churn boundary that does not introduce jerky motion.

Required invalidation thinking:
- Re-issue or refresh the target when:
- the move target changed meaningfully
- the refresh timer expired
- recovery or stuck handling is active
- movement state changed in a way that affects nav sampling behavior
- Do not suppress `get_next_path_position()` just because the target did not change.

Near-vs-far interaction:
- Far enemies should benefit the most from slower refresh and direct chase behavior.
- Near enemies may still need more responsive nav updates, but those updates should remain cached between meaningful changes.
- The near-vs-far rule from Slice 1 should stay compatible with this slice rather than introducing a separate contradictory timing model.

Implementation order inside Slice 2:
1. Keep `get_next_path_position()` continuous.
2. Measure when and why target refresh / repath work is actually happening.
3. Verify and document the correct refresh / invalidation rules.
4. Identify a safer, narrower optimization boundary than the rejected target-refresh throttling attempt.
5. Add stronger per-enemy staggering only if burst alignment is still a visible or measured problem.

Principle to preserve:
- Navigation refresh timing should suppress repath churn without breaking continuous path following.
- If a candidate optimization introduces visible jerkiness, reject it even if it looks correct in code.

Acceptance checks:
- lower `_refresh_navigation_cache()` frequency in the dense scene
- lower NavigationAgent next-position churn
- no visible movement stutter or synchronized bursts
- no stop-and-go movement caused by stale cached path points

Risk:
- timing logic can become harder to reason about if cadence and invalidation rules are overcomplicated
- adding extra stagger too early could hide the real cache bug instead of solving it
- caching the final next path position across physics ticks is explicitly rejected for this slice because it breaks continuous movement
- naive target-refresh throttling is also currently rejected because it still produced jerky movement in-engine

## Slice 3
### Crowd and rank scan reduction

Purpose:
- reduce repeated registry-wide scans that scale badly with enemy count

Files:
- `godot/scripts/enemy/movement/enemy_crowd_query.gd`
- `godot/scripts/enemy/enemy_controller.gd`
- `godot/scripts/enemy/movement/enemy_crowd_response.gd`

Current issue:
- `collect_nearby_enemy_positions()`, `collect_local_enemy_positions()`, and `get_target_distance_rank()` each walk the shared enemy registry directly.
- In dense scenes this creates repeated O(N^2) work across goal spread scoring, frontline gating, and close-range movement.
- This is the main dense-scene crowd-awareness cost center after path-query cost and nav-refresh correctness.

Why this matters:
- Goal selection uses nearby-enemy data for spread-aware scoring.
- Frontline gating computes target-distance rank near the player.
- Close-adjust, yield, and push-resolution paths all need local neighbor information.
- When these queries all scan the same global registry repeatedly, the crowd-logic cost compounds even if individual loops look simple in isolation.

Planning focus:
- identify which scans are global and which are local
- broaden reuse of one local-neighbor result across close-adjust, yield, and push-resolution work where behavior allows it
- reduce how often frontline rank must be recomputed
- escalate to stronger spatial partitioning only if simpler reuse is still not enough

Decision taken for this slice:
- Start with reuse and recomputation reduction before introducing a more complex spatial structure.
- Treat registry-scan reduction as a crowd-query architecture cleanup, not as a reason to redesign melee behavior.
- Keep crowd reactions readable and responsive; stale-feeling reuse is not acceptable just to win raw perf numbers.

Likely levers:
- broader local cache reuse
- state-sensitive query suppression
- short-lived rank reuse
- optional spatial bucketing if needed later

Current query families to distinguish:
- Global-ish scans:
- `collect_nearby_enemy_positions()` for goal spread scoring around the player-centered candidate ring
- `get_target_distance_rank()` for active melee frontline checks
- Local scans:
- `collect_local_enemy_positions()` and cached local neighbor fetches used by close-adjust, yield, and external displacement resolution

Preferred optimization direction:
- reuse one local-neighbor result across multiple close-range consumers where the same radius or a compatible radius is already good enough
- avoid querying local neighbors in states that do not need crowd response
- narrow how often frontline rank must be recalculated instead of computing it every relevant physics tick
- delay spatial buckets or partitions until after simpler reuse has been measured

First implementation pass landed:
- keep Slice 3 controller-centered before changing `enemy_crowd_query.gd` internals
- reuse one shared local-neighbor query result across close-adjust, yield, and external displacement resolution
- add short-lived controller-side reuse for frontline rank checks
- leave `enemy_crowd_response.gd` behavior logic unchanged
- leave stronger spatial structures out of this pass

Implementation order inside Slice 3:
1. Identify which queries are duplicated across the same enemy update path.
2. Broaden local-neighbor reuse where the current behavior can tolerate it.
3. Reduce unnecessary frontline-rank recomputation.
4. Measure dense-scene registry-scan counts again.
5. Only if still needed, consider a stronger spatial lookup structure.

Principles to preserve:
- The goal is fewer scans, not a different melee behavior model.
- Query reuse should stay short-lived and behavior-aware.
- Global scans and local scans should not be treated as the same problem; optimize them separately when useful.
- Do not add a heavier data structure until the simpler cache-and-reuse path proves insufficient.

Acceptance checks:
- fewer registry scans per frame
- dense packs still look responsive
- no stale-feeling crowd reactions
- local crowd behavior still reacts quickly enough near the player
- spread-aware goal selection still avoids obvious clumping

Risk:
- overly aggressive reuse can delay crowd reactions and make melee packs feel sluggish
- introducing spatial partitioning too early can increase complexity before the real low-risk wins are taken

## Slice 4
### Close-range steering cleanup

Purpose:
- reduce repeated passes over the same neighbor data without changing melee feel

Files:
- `godot/scripts/enemy/movement/enemy_crowd_response.gd`
- `godot/scripts/enemy/enemy_controller.gd`

Current issue:
- `EnemyCrowdResponse` loops the same local neighbor list multiple times for crowd pressure, side penalties, and yield direction scoring.
- This is not the top spike alone, but it compounds the goal-selection and crowd-query cost when many enemies are already near the player.

Planning focus:
- measure close-adjust and melee-hold cost separately
- derive shared crowd metrics once when the same local picture is reused
- reduce redundant penalty probes where the current side/state is already stable
- keep behavior-preserving changes ahead of deeper redesign

Acceptance checks:
- no new jitter
- no visible change in melee feel
- measurable reduction in close-range overhead

Risk:
- this slice is the easiest one to accidentally turn into a behavior change

## Recommended Order
1. Slice 1: goal-selection cost reduction
2. Slice 2: navigation refresh correctness and cadence
3. Slice 3: crowd and rank scan reduction
4. Slice 4: close-range steering cleanup

## Validation Notes
- Use `godot/scenes/main/DemoMain.tscn` as the primary repro scene.
- Compare the smaller enemy baseline against the dense crowd fixture.
- Check corner and wall-adjacent behavior immediately after any goal-selection change.
- Use the shared `F3` debug surface only as support; do not mistake overlay stats for a full profiling pass.

## Restart Notes
1. Treat this document as the active current plan.
2. Treat the earlier enemy navigation performance plan as historical context only.
3. Validate each slice in isolation before moving to the next one.
4. Revert only the current slice if behavior quality drops.

## Progress Tracker
- [ ] Slice 1 started
- [ ] Slice 1 validated
- [ ] Slice 2 started
- [ ] Slice 2 validated
- [ ] Slice 3 started
- [ ] Slice 3 validated
- [ ] Slice 4 started
- [ ] Slice 4 validated
