# Enemy Crowd Performance And Contact Stability Slice

## Status
- `active`

## Purpose
- Track the enemy crowd-performance work that should be resumed later.
- Preserve the current restart context after rolling back the broader performance slice.
- Keep the agreed re-entry order in one place for the next session.

## Current Reality
1. The broader enemy navigation and movement performance slice was rolled back.
2. We intentionally kept only the agreed nav-refresh behavior changes in code:
   - `nav_refresh_far_distance = 3.0`
   - `nav_refresh_interval_near = 0.1`
   - `nav_refresh_interval_far = 0.5`
   - no forced per-frame `APPROACH` refresh
   - continuous movement preserved while using slower refresh timing
3. No other performance-slice tuning or helper-cache changes are currently active.
4. The next restart should treat the remaining work as a fresh implementation pass, not as an in-progress partially trusted branch.

## Scope
- Enemy crowd performance in dense corner and surround scenarios.
- Near-player navigation churn and crowd update cost.
- Goal-selection cost, refresh staggering, and crowd-query reuse when they are reintroduced carefully.
- Validation in `DemoMain` dense-pack scenarios.

## Out Of Scope
- New enemy archetypes.
- Traversal or dodge work.
- Combat feedback presentation work.
- Broad AI redesign outside the enemy movement stack.

## Confirmed Decisions
1. `melee_hold` should not be changed casually.
2. Close-range jitter and crowd oddities should be diagnosed before broader rewrites.
3. Approach-side nav refresh should be slower, but movement must remain continuous.
4. Future performance work should be reapplied in small validated slices, not as one broad pass.

## Current Baseline Kept In Code
1. `APPROACH` no longer forces immediate nav refresh just because the enemy is within the old near-distance threshold.
2. Approach movement still reads the current nav step every physics tick, so enemies do not fall into move-stop-move behavior.
3. The near/far nav refresh split is currently:
   - `<= 3m`: `0.1s`
   - `> 3m`: `0.5s`

## Re-Entry Plan
1. Re-validate the current nav-refresh baseline first.
   - Confirm outer enemies no longer spam recalculation.
   - Confirm approach motion still looks continuous.
2. Reintroduce goal-selection optimization carefully.
   - Start with conservative tuning only.
   - Validate corner and wall-adjacent behavior immediately.
3. Reintroduce frame-staggering only after goal selection is stable.
4. Reintroduce crowd-query reuse only after stagger timing is validated.
5. Treat any close-range steering cache work as last and optional.

## Restart Order For Tomorrow
1. Validate current nav-refresh settings in the stress scene.
2. If performance still needs work, create a new narrow goal-selection slice first.
3. Only after that, consider a new timing-stagger slice.
4. Keep every later slice independently revertable.

## Acceptance Checks
1. Dense-pack enemies should not visibly jitter because of approach-side recalculation churn.
2. Approach movement should remain continuous.
3. Corner and wall-adjacent goal picks should stay believable.
4. Any future optimization step must preserve the current melee baseline unless explicitly changed.

## Open Risks
1. Goal-selection tuning can make enemies prefer bad wall-side targets if candidate coverage or projection tolerance is reduced too aggressively.
2. Frame-staggering can hide spikes but make timing harder to reason about.
3. Crowd-query reuse may have only modest payoff unless the call pattern clearly duplicates work.

## Next Step
- Resume from the current nav-refresh baseline and start with a fresh, narrow goal-selection optimization slice only if more performance work is still needed.
