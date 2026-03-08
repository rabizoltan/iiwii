# Combat Feedback And Debug Behavior Slice

## Status
- `blocked`

## Goal
Define the minimum combat feedback and debug visibility required after the behavior rules are known.

## Why This Is Separate
- Current HP and debug overlays exist for prototype validation only.
- They should not silently evolve into long-term behavior without explicit scope.
- Shared developer debug controls now belong to the dedicated debug control panel slice, not this slice.

## Scope Candidates
- enemy HP presentation
- hit confirmation
- death feedback
- log vs on-screen debug responsibilities

## Questions That Must Be Answered Before This Slice Starts
1. Should enemy HP remain visible at all times, only in debug mode, or only on hit?
2. What is the minimum acceptable hit feedback for the next milestone?
3. What is the minimum acceptable death feedback for the next milestone?
4. Should debug overlay be global, per-enemy, or fully disabled by default?
5. Which debug information must remain available during future behavior work?

## Proposed Success Criteria
This slice can start only after the questions above are answered.

Once specified, success criteria should define:
1. exact HP visibility rule
2. exact debug toggle rule
3. exact minimum hit/death feedback
4. validation method in the demo scene
