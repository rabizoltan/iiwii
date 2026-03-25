# Enemy Dense-Scene Navigation Performance Slice

## Status
- `completed`

## Purpose
- Track the current dense-scene enemy navigation performance pass.
- Keep the revised optimization direction separate from the earlier failed attempt.
- Preserve a clean execution plan focused on measurable runtime-cost reduction without sacrificing readable melee surround behavior.
- Record the accepted dense-scene optimization changes that landed for this pass.

## Scope
- Goal-selection cost in dense scenes.
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
- Keep rejected navigation-refresh ideas out of this active plan.

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
- keep Slice 2 controller-centered before changing `enemy_crowd_query.gd` internals
- reuse one shared local-neighbor query result across close-adjust, yield, and external displacement resolution
- add short-lived controller-side reuse for frontline rank checks
- leave `enemy_crowd_response.gd` behavior logic unchanged
- leave stronger spatial structures out of this pass

Implementation order inside Slice 2:
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

## Slice 3
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

First implementation pass direction:
- keep this slice behavior-preserving and local to `enemy_crowd_response.gd`
- fold repeated left/right penalty probes into one shared helper
- fold repeated yield-direction penalty probes into one shared helper
- do not change crowd-pressure math, state transitions, or nav-agent usage

Current implementation status:
- Slice 3 cleanup has started in `enemy_crowd_response.gd`
- repeated directional penalty scans now share one helper path
- behavior validation was accepted before closure

## Recommended Order
1. Slice 1: goal-selection cost reduction
2. Slice 2: crowd and rank scan reduction
3. Slice 3: close-range steering cleanup

## Validation Notes
- Use `godot/scenes/main/DemoMain.tscn` as the primary repro scene.
- Compare the smaller enemy baseline against the dense crowd fixture.
- Check corner and wall-adjacent behavior immediately after any goal-selection change.
- Use the shared `F3` debug surface only as support; do not mistake overlay stats for a full profiling pass.

## Closure Notes
1. Treat this document as the completed record for the dense-scene navigation performance pass.
2. Treat the earlier enemy navigation performance plan as historical context only.
3. Slice 2 from the earlier draft was rejected and intentionally removed from this final plan.
4. If future dense-scene work resumes, start a new slice rather than reopening this one.

## Progress Tracker
- [x] Slice 1 started
- [x] Slice 1 validated
- [x] Slice 2 started
- [x] Slice 2 validated
- [x] Slice 3 started
- [x] Slice 3 validated
