# Enemy Crowd Performance And Contact Stability Slice

## Status
- `active`

## Purpose
- Remove avoidable enemy crowd slowdown in the dense-pack corner case.
- Enforce the intended contact rule that rear enemies must not push through or propagate pressure through the front line.
- Reduce near-player navigation churn so crowded melee behavior stays stable and cheaper.

## Why This Slice Exists
- Recent profiling of the dense-pack corner scenario shows the slowdown is dominated by collision and movement resolution under compression, with excessive navigation refresh churn adding extra cost.
- The current accepted baseline already removed baseline player shove and limited active melee front-line participation, but the runtime still appears to allow enough enemy contact pressure and near-player movement churn to create avoidable slowdown.
- This is now a cross-cutting runtime behavior and performance issue, so it should be handled as a dedicated slice instead of ad-hoc tuning.

## Problem Statement
When the player stands in a corner and many melee enemies compress into the same area, frame time degrades sharply. Profiling indicates that enemies are not just paying for dense contact resolution; they are also refreshing navigation almost every physics tick while packed near the player. The intended crowd rule is narrower than the current runtime outcome: the player may pressure only the first line, and rear enemies should queue or wait rather than transmitting push through the full pack.

## Current Evidence
### Profiler Findings
1. `move_and_slide()` and movement finalization dominate the hot path in the dense-pack scenario.
2. Navigation cache reuse and near-player refresh behavior are likely still important contributors, even though collision resolution remains the dominant expense.
3. Goal selection and path scoring are present but are not the primary hotspot in the captured log.
4. Nearby-enemy queries and local-enemy cache queries are comparatively small and do not currently appear to be the main bottleneck.
5. The main stress-case bottleneck appears to be collision plus excessive inward crowd pressure.

### Behavior Findings
1. The accepted crowd-pressure baseline says normal player movement should not shove enemies and rear enemies should queue or wait instead of forcing through the front line.
2. The current melee runtime still contains enemy-side yield and crowd-chain pressure logic near the player.
3. The current melee runtime still uses near-player navigation refresh in `close_adjust`, even in the exact stress case where enemies should prefer local settling over repeated path refresh.
4. The current runtime contract needs to be tightened so enemy-to-enemy push propagation is no longer part of the accepted melee baseline.

## Refactor Goal
Reach a dense-pack melee baseline where front-line enemies can body block and pressure the player, rear enemies queue without transmitting push through the whole pack, near-player enemies stop refreshing navigation excessively, and the corner-surround scenario performs materially better without changing the broader single-enemy or small-pack behavior model.

## Scope
- Enemy close-range crowd interaction in `approach`, `close_adjust`, and `melee_hold`
- Enemy-to-enemy contact and push-propagation rules near the player
- Near-player navigation cache and goal-refresh policy
- Profiling and validation for the dense-pack corner case
- Documentation updates for the revised contact/performance contract

## Out Of Scope
- Full crowd simulation
- New traversal or dodge behavior
- New enemy archetypes
- Combat feedback presentation work
- Broad physics engine changes outside the enemy runtime slice

## Primary Findings
1. Dense enemy slowdown is primarily driven by collision resolution under compression plus excessive nav refresh churn.
2. The current runtime still includes enemy-side yield/chain-pressure behavior that conflicts with the intended no-push-through-front-line rule.
3. Near-player navigation policy is too eager in crowded close-range states and is likely paying for refreshes that do not materially improve behavior.
4. Enemies that are already inside valid melee range still have runtime paths that try to improve position, which adds unnecessary contact pressure and movement churn in dense packs.

## Secondary Findings
1. Goal selection and path tiebreak work should still be kept under observation, but they are not the first optimization target from the current log.
2. Existing frontline gating is useful, but it does not by itself prevent chain pressure or contact-driven solver thrash.
3. This slice changes behavior contract, not just tuning, so canonical docs must be updated together with runtime changes.

## Restart Snapshot
Date: 2026-03-18

1. The temporary runtime experiments from this slice were intentionally discarded from code.
2. This document is now the clean restart plan for a fresh implementation pass.
3. The profiler evidence gathered before the reset is still useful and should remain the starting reference.
4. The latest captured stress-case logs still point to the same main problem areas:
   - `move_slide_share` is about `0.43`
   - `finalize_share` is about `0.48`
   - `physics_avg_ms` ramps from about `0.149` to `0.195`
   - dense corner-surround behavior degrades over time as compression increases
5. Working interpretation for the restart:
   - collision/compression is still the dominant hotspot
   - nav refresh and near-player movement churn are still strong secondary suspects
   - the reported mid-run spike looks more like the normal crowd-compression ramp than a unique subsystem burst
   - the next best implementation order is still: contact rule tightening, near-player nav suppression, then rear-enemy queue stabilization

## Guardrails
1. Preserve the accepted baseline that normal player locomotion does not shove enemies out of the way.
2. Keep authored combat displacement available as a separate path; do not remove explicit external displacement support used for attacks or future combat effects.
3. Do not broaden this slice into traversal, combat feedback, or a full AI redesign.
4. Preserve readable melee pressure from the front line even while removing rear-line push propagation.
5. Prefer simple local rules near the player over more solver complexity.

## Invariants
1. A single enemy must still be able to approach and enter melee cleanly.
2. Small enemy groups must remain readable and threatening.
3. Front-line enemies may body block the player, but rear enemies must not push the whole pack inward.
4. Enemies already in valid melee hold should not churn navigation because of tiny nudges.
5. External authored displacement must remain opt-in and clearly separated from baseline locomotion contact.
6. Enemies already inside valid melee range must not keep trying to move closer just to improve their position slightly.

## Proposed Runtime Direction
### 1. Contact Rule Tightening
- Treat enemy-to-enemy push propagation as disallowed baseline behavior near the player.
- Rear enemies should queue, orbit shallowly, or stall instead of transmitting inward pressure through settled front-line enemies.
- If necessary, accept softer overlap tolerance or local dead-zone behavior rather than rigid chain compression.

### 2. Near-Player Nav Suppression
- Suppress or heavily relax nav refresh in `close_adjust` and `melee_hold`.
- Refresh only when the player moves meaningfully, the enemy leaves the accepted melee envelope, or the current goal becomes truly invalid.
- Avoid paying for navigation refresh when contact pressure is the only thing changing.

### 3. Stable In-Range Hold
- Treat valid melee range as a true hold state, not as a prompt to keep hunting for a slightly better spot.
- Remove or reduce logic that makes already-in-range enemies continue moving closer to the player.
- Allow facing updates and minimal settling only when needed, but do not let tiny nudges restart inward locomotion.

### 4. Front-Line Priority
- Keep the active front-line cap, but validate whether rear enemies need stronger gating before entering close-range movement logic.
- Rear enemies should stay in cheaper queue/approach behavior until a true front-line opening exists.

### 5. Authored Displacement Boundary
- Keep `apply_external_movement_influence()` for authored displacement only.
- Remove or disable any baseline enemy movement logic that effectively recreates crowd-push behavior through yield or chain-pressure rules.

## Execution Slices
1. Contract and observability slice.
   - Update the melee runtime contract to state that rear enemies do not push through the front line.
   - Keep the current profiler instrumentation and define the validation counters for this slice.
2. Enemy contact-pressure cleanup slice.
   - Audit `yield`, `chain_pressure`, and related near-player push behavior.
   - Remove or disable baseline enemy-to-enemy push propagation while preserving authored displacement.
3. Near-player navigation policy slice.
   - Reduce nav refresh frequency in `close_adjust` and `melee_hold`.
   - Make near-player movement rely more on cached/local behavior and less on repeated nav queries.
4. In-range hold cleanup slice.
   - Remove or sharply reduce logic that makes already-valid melee enemies keep improving their position.
   - Treat small contact nudges as hold-preserving noise instead of a reason to move inward again.
5. Front-line queue stabilization slice.
   - Validate whether rear enemies need stronger front-line gating or earlier refusal to enter close-adjust.
   - Ensure rear enemies wait or orbit cheaply instead of compressing the pack.
6. Validation and docs closure slice.
   - Re-profile the corner-surround scenario.
   - Compare before/after hotspot distribution and confirm the crowd rule matches runtime behavior.

## Validation Plan
1. Reproduce the corner-surround case with enemy profiling enabled.
2. Compare before/after values for:
   - `move_slide_share`
   - `nav_cache_refreshes`
   - `nav_cache_hits`
   - `goal_refresh_triggers`
   - `frontline_checks`
   - `close_adjust_calls`
3. Validate behavior visually:
   - player cannot push through multiple lines
   - rear enemies do not shove the front line inward
   - front-line enemies still create readable pressure
   - enemies already in valid melee range do not keep creeping inward
   - no visible jitter or slot-swapping regression
4. Keep manual DemoMain validation as the required runtime check until a stronger automated path exists.

## Success Criteria
1. Rear enemies no longer push through or propagate force through the front line during baseline locomotion contact.
2. Dense corner-surround scenarios show materially lower nav refresh churn than the captured baseline.
3. Dense corner-surround scenarios perform better or at minimum stop degrading because of avoidable AI churn.
4. Front-line melee pressure remains readable and threatening.
5. Authored combat displacement still works through the dedicated external influence path.
6. Enemies already in valid melee range hold cleanly instead of repeatedly trying to move closer.

## Risks
1. Making enemies too passive could reduce perceived pressure if front-line occupancy becomes too static.
2. Over-suppressing nav refresh could cause enemies to look stuck if the player moves out of the envelope and refresh conditions are too strict.
3. Tightening contact behavior may require a docs update wherever older soft chain-pressure language still appears.

## Todo
- [ ] Confirm the close-range behavior contract is the intended target before re-implementation.
- [ ] Audit the exact runtime paths that still create enemy-to-enemy push propagation.
- [ ] Identify the smallest safe nav-refresh suppression change for close-range states.
- [ ] Identify and remove the smallest runtime paths that make already-in-range enemies keep improving position.
- [ ] Define the before/after profiler checkpoints for validation.

## In Progress
- [ ] No code slice currently in progress. The implementation is being restarted from a clean code baseline.

## Done
- [x] Profile the dense corner-surround slowdown and capture the first hotspot breakdown.
- [x] Confirm that the current issue is dominated by dense contact plus nav refresh churn rather than by crowd-neighbor query cost.
- [x] Update the close-range behavior contract to match the no-push-through-front-line rule.
- [x] Preserve the implementation plan and profiler findings after discarding the experimental code changes.
