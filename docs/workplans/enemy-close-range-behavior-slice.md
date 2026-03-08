# Enemy Close-Range Behavior Slice

## Status
- `active`

## Goal
Define and implement the intended enemy behavior once enemies reach the player.

## Why This Is Separate
- Current enemies chase the player and stop at a basic hold distance.
- That is enough for a prototype, but not enough to define intended combat behavior.

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
4. Once a melee enemy reaches valid engage distance, it should hold position and attack from there.
5. If the player moves, melee enemies should follow and re-establish valid engage distance.
6. Multiple melee enemies should use soft spreading:
   - prefer a less crowded nearby reachable position
   - do not try to immediately full-surround the player
7. The next slice should improve close-range readability without making enemy surround behavior feel oppressive.

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
