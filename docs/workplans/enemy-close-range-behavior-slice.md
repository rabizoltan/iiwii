# Enemy Close-Range Behavior Slice

## Status
- `stale`

## Purpose
- Preserve the original delivery context for the melee close-range slice.
- Point future implementation work at the renewed source-of-truth behavior contract.

## What This Slice Was About
1. Move melee enemies to engage distance near the player.
2. Hold and face the player once in acceptable melee range.
3. Reduce obvious clumping with soft spreading.
4. Validate dense crowd behavior in the demo scene.

## What We Learned
1. The broad slice goal was correct, but the detailed near-player movement contract needed to be written more explicitly.
2. Near the player, repeated goal resampling and overlapping local heuristics quickly produce visible vibration and slot churn.
3. Physical crowd interaction is desirable, but it must be constrained so it does not turn settled melee enemies into jittering wall elements.
4. The final architecture needs a cleaner separation between:
   - approach behavior
   - close-range local adjustment
   - stable melee hold

## Current Source Of Truth
- The active melee behavior contract now lives in [enemy-melee-behavior-v1.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/ai/enemy-melee-behavior-v1.md).

## Expected Rebuild Direction
1. Rebuild against the explicit `approach -> close_adjust -> melee_hold` model.
2. Keep melee-hold validity independent from cached goal ownership.
3. Allow slight enemy/player push, but keep near-player crowd flow mostly lateral.
4. Treat visible vibration as a bug, not acceptable tuning noise.

## Why This Workplan Is `stale`
1. It originally mixed delivery history, implementation notes, tuning attempts, and desired long-term behavior.
2. That made it a poor source of truth for a clean rebuild.
3. The architecture doc above should now be used instead for future implementation decisions.
