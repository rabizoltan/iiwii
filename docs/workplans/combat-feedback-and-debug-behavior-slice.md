# Combat Feedback And Debug Behavior Slice

## Status
- `blocked`

## Goal
Define the minimum player-facing combat feedback and the remaining developer-facing debug visibility required after the movement and crowd-pressure rules are stable.

## Why This Is Separate
- Current HP and debug overlays exist for prototype validation only.
- They should not silently evolve into long-term behavior without explicit scope.
- Shared developer debug controls now belong to the dedicated debug control panel slice, not this slice.
- Enemy movement and crowd-pressure baselines are now stable enough that feedback work can be specified without using feedback as a movement-design crutch.

## Scope Candidates
- enemy HP presentation
- hit confirmation
- death feedback
- log vs on-screen debug responsibilities

## Current Runtime Baseline
1. Shared debug controls already exist through the debug control panel slice.
2. Enemy floating status text is currently disabled in runtime.
3. Enemy nav-path debug and profiling exist for developer validation.
4. Player attack, enemy close-range behavior, and player-enemy crowd pressure have all reached stable baselines.
5. This slice is blocked by presentation and UX decisions, not by missing technical hooks.

## Questions That Must Be Answered Before This Slice Starts
1. Should enemy HP remain visible at all times, only in debug mode, or only on hit?
2. What is the minimum acceptable hit feedback for the next milestone?
3. What is the minimum acceptable death feedback for the next milestone?
4. Should debug overlay be global, per-enemy, or fully disabled by default?
5. Which debug information must remain available during future behavior work?

## What Is Already Decided
1. Shared debug toggles remain owned by the debug control panel, not by combat feedback code.
2. Enemy locomotion and crowd-pressure debugging are developer-facing concerns, not default player-facing UI.
3. Future traversal escape behavior belongs to a later traversal slice, not this one.

## Proposed Success Criteria
This slice can start only after the questions above are answered.

Once specified, success criteria should define:
1. exact HP visibility rule
2. exact debug toggle rule
3. exact minimum hit/death feedback
4. validation method in the demo scene
