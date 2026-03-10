# Enemy Close-Range Behavior Slice

## Status
- `completed`

## Goal
Define and implement the intended enemy behavior once enemies reach the player.

## Step Status Board
- Step 0 - Lock behavior rules: `completed`
- Step 1 - Implement engage-goal movement and hold behavior: `completed`
- Step 2 - Validate multi-enemy spread and follow behavior: `completed`
- Step 3 - Close out docs and verification notes: `completed`

## Why This Is Separate
- Current enemies chase the player and stop at a basic hold distance.
- That is enough for a prototype, but not enough to define intended combat behavior.
- This slice is about melee navigation, local positioning, following, and hold behavior.
- Melee attack/hit logic is intentionally out of scope for this slice.

## Scope Candidates
- stop distance
- preferred attack distance
- spreading around the player
- overlap avoidance
- multi-enemy local positioning
- corner recovery expectations
- whether enemies should circle, hold, or pressure forward

## Behavior Already Specified By Current Docs
1. Melee enemies gather around the target close enough to engage.
2. Goal selection should prefer the closest reachable nearby candidate by path length.
3. Soft occupancy should reduce obvious clumping without hard slot locking.
4. Stuck detection and recovery must exist and must change the situation.
5. Path cost remains the dominant term when choosing positions.

## Behavior Agreed For This Slice
1. This slice is melee-first.
2. Melee enemies should not slowly orbit/circle around the player.
3. Melee enemies should not keep pushing for tighter contact once they are in valid engage distance.
4. Once a melee enemy reaches valid engage distance, it should hold position and face the player from there.
5. If the player moves, melee enemies should follow and re-establish valid engage distance.
6. Multiple melee enemies should use soft spreading:
   - prefer a less crowded nearby reachable position
   - do not try to immediately full-surround the player
7. The next slice should improve close-range readability without making enemy surround behavior feel oppressive.
8. Slight physical nudging between enemies is acceptable as long as it does not cause visible orbit-churn or constant position swapping.
9. Full stuck-recovery escalation is out of scope unless simpler movement/follow behavior proves insufficient.

## Proposed Success Criteria
1. Melee enemies chase until they reach valid engage distance.
2. Once in engage distance, melee enemies hold rather than orbit or press inward.
3. If the player moves away, melee enemies follow and re-acquire engage distance.
4. Multiple melee enemies prefer less crowded nearby reachable positions through soft spreading.
5. The system avoids fast oppressive full-surround behavior.
6. Corner and crowd cases use recovery that improves the situation instead of repeatedly pushing into the same failure.
7. Validation in the demo scene confirms:
   - one-enemy hold behavior
   - multi-enemy soft spreading
   - player-moves-away follow behavior
   - corner/crowd recovery remains acceptable

## Implemented Outcome
1. Melee enemies now choose nearby engage goals around the player instead of directly chasing raw player position.
2. Once in engage range, they hold and face the player rather than orbiting.
3. Soft spreading is implemented through nearby-candidate scoring, not hard slot locking.
4. Enemy collision is enabled so crowd shape is physical rather than purely visual.
5. Frontline enemies now use a constrained crowd-yield response when the player presses into them:
   - direct give-ground
   - side-shuffle alternatives when straight-back movement is blocked
   - limited pressure propagation into nearby packed enemies
6. Debug support now exposes goal/path state and crowd-yield diagnostics through the existing enemy debug output.
7. Runtime profiling support was added so enemy-controller cost can be inspected without guessing:
   - aggregated enemy-controller timing in the `F3` debug menu
   - periodic profiling snapshots written to `user://debug/enemy_profile.log`
8. A light performance pass reduced avoidable script-side cost without changing accepted close-range behavior:
   - shared enemy registry instead of repeated group scans
   - cached local crowd-neighbor queries
   - throttled debug label and nav-debug redraw
   - light far-enemy nav-refresh throttling tuned to preserve smooth motion

## Manual Validation Notes
- Demo scene was expanded to include a denser multi-line enemy crowd for close-range pressure testing.
- Current feel target is acceptable:
  - player cannot easily pass straight through a dense hostile crowd
  - frontline enemies no longer feel like an immovable wall
  - dense packs deform and shuffle under pressure in a more natural way than the prototype stop-distance behavior
- Profiling validation established the current optimization boundary:
  - script-side goal selection and crowd-yield are not the main remaining cost
  - the dominant remaining buckets are engine-side `move_and_slide()` and navigation-agent query work
  - the accepted optimization pass improves script cost while preserving smooth movement and reliable enemy collision

## Residual Risks
- Dense-crowd push feel is tuning-sensitive and may need follow-up balancing rather than structural changes.
- The crowd-yield model is still local and heuristic-based; it is not a full crowd simulation.
- Large-scale enemy counts will likely need later architectural work beyond this slice:
  - shared occupancy/spatial-query services
  - update budgeting / LOD for large enemy groups
  - a cheaper crowd collision model than full per-enemy close-pressure resolution
