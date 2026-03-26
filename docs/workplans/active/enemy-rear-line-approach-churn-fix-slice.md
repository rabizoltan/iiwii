# Enemy Rear-Line Approach Churn Fix Slice

## Status
- `active`

## Purpose
- Stop rear-line enemies from constantly making small inward `APPROACH` adjustments when the frontline is already full.
- Preserve the preferred melee feel of the `4bdd6f0` baseline while reducing visible second-line jitter.
- Keep the change surface narrow and avoid reopening broad navigation redesign work.

## Why This Slice Exists
1. The earlier crowd-performance diagnostics are complete and now live in [completed/enemy-crowd-performance-and-contact-stability-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/completed/enemy-crowd-performance-and-contact-stability-slice.md).
2. The current remaining gameplay issue is narrower:
   - rear-line enemies beyond roughly `2.5m` keep moving constantly
   - they make small blocked adjustments even when no real opening exists
   - the behavior reads as perpetual inward intent rather than a stable second line
3. Recent code and behavior review point to a policy problem, not a primary navmesh authoring problem:
   - non-frontline enemies are forced back into `APPROACH`
   - they keep chasing inward engage goals
   - goal refresh and stuck recovery amplify the small-movement loop

## Scope
- Rear-line enemy motion policy near the player in `DemoMain`.
- Narrow controller-side state behavior and goal ownership for blocked second-line enemies.
- Fixing request wiring that prevents intended goal-selection behavior from activating correctly.
- Validation against the preferred current melee feel baseline.

## Out Of Scope
- Broad AI redesign.
- Reopening the older nav-refresh timing experiments as a primary solution.
- General crowd system rewrite, avoidance adoption, or slot-locking.
- Combat feedback/presentation work.
- Scene-layout or navmesh-authoring changes unless a concrete mismatch appears during validation.

## Confirmed Evidence
1. Rear-line enemies in roughly the `2.5m-3.0m` band keep moving instead of settling.
2. The current controller forces non-frontline near-player enemies back to `APPROACH`.
3. Those same enemies keep chasing inward engage goals instead of holding a stable rear-line intent.
4. `APPROACH`-only stuck recovery and repeated goal reacquire can read as visible small correction churn.
5. The preferred `4bdd6f0` baseline feel is worth preserving while addressing only this narrower problem.

## Root-Cause Statement
- The current runtime gives blocked rear-line enemies no stable near-player waiting behavior.
- They are forced into `APPROACH`, and `APPROACH` continues to pursue inward movement goals.
- That makes blocked second-line enemies keep receiving steering corrections and small recovery motions even when the frontline is already full.

## Planned Fix Order

### Step 1 - Break The Rejected-Enemy Inward Loop
Status:
- `active`

Intent:
- When a unit is rejected from frontline close-range participation, stop treating it as a normal inward-moving `APPROACH` enemy.
- Give rejected near-player enemies a stable non-inward behavior so they do not keep performing tiny blocked approach corrections.

Reason:
- This is the smallest change most directly tied to the actual root cause.
- Goal ownership matters, but the deeper issue is that rejected enemies currently have no stable near-player state other than inward `APPROACH`.

Implementation direction:
1. Adjust the frontline-rejection path in `enemy_controller.gd` so rejected near-player enemies do not remain in a perpetual inward-approach loop.
2. Ensure the resulting behavior still preserves a readable active frontline and does not reopen broad crowd instability.

### Step 2 - Rear-Line Goal Ownership Suppression
Status:
- `active`

Intent:
- When a unit is rejected from frontline participation, stop letting it keep or rapidly reacquire an inward engage goal.

Reason:
- This remains necessary even after Step 1, because inward goal ownership can otherwise keep rearming the same motion loop.

Implementation direction:
1. Gate goal refresh / goal reuse so rejected rear-line enemies do not keep reclaiming inner engage targets every few tenths of a second.
2. Keep the change narrow to controller/runtime-policy goal handling unless validation proves a deeper change is required.

### Step 3 - Goal-Selection Distance Wiring Fix
Status:
- `active`

Intent:
- Populate the goal-selection request distance correctly so the existing direct-chase vs ring-goal branch behaves as designed.

Reason:
- This is a narrow correctness fix already visible in the current controller/selector path.
- It is not expected to be the primary fix for the `2.5m-3.0m` band, but it should be corrected while this slice is open.

### Step 4 - Re-evaluate Frontline Forcing Only If Needed
Status:
- `pending`

Intent:
- Revisit the exact frontline demotion rule only if Steps 1-3 do not reduce the rear-line motion enough.

Reason:
- This has higher gameplay-risk than the first three fixes and should remain a second-pass option.

## Validation Plan
1. Use the dense crowd repro in `DemoMain`.
2. Watch enemies in the `2.5m-3.5m` rear-line band specifically.
3. Confirm they stop performing constant tiny inward corrections when the frontline is blocked.
4. Confirm the frontline still forms and remains active.
5. Confirm the preferred overall melee feel of the current baseline is preserved.

## Acceptance Checks
1. Rear-line enemies no longer read as permanently advancing when no opening exists.
2. Visible second-line jitter is materially reduced.
3. Frontline enemies still form a readable active melee line.
4. The change does not reopen the earlier broad rejection-storm or FPS-regression problem.

## Open Risks
1. If the rejected-enemy behavior is changed too aggressively, rear enemies may appear to freeze unnaturally instead of reading as a stable queue.
2. Suppressing goal ownership without breaking the inward-approach loop may only replace jitter with stop/start reacquire behavior.
3. Fixing only the distance wiring may improve farther-out behavior more than the `2.5m-3.0m` band.
4. If the frontline demotion rule remains too strict, some low-amplitude churn may survive after the first pass.

## Next Step
- Implement Step 1, Step 2, and Step 3 in the smallest possible controller-side patch, then validate the dense-pack rear-line behavior in `DemoMain`.
