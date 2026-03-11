# Enemy Melee Behavior v1

## Status
- Target behavior contract for the melee rebuild.
- Use this as the source of truth for close-range enemy behavior.
- Runtime implementation is expected to be rebuilt against this document.

## Purpose
Define melee enemy movement and crowd interaction that is:
- readable to the player
- stable near the player
- compatible with simple navmesh-driven movement
- feasible without full crowd simulation

## Core Design Priorities
1. Stability in melee is more important than aggressive local optimization.
2. Enemies already in good melee range must look settled.
3. Physical interaction between enemies is allowed, but it must not create visible vibration, oscillation, or slot-swapping.
4. Near the player, the system should prefer simple local rules over repeated goal solving.
5. The controller should be structured as a small explicit state machine, not a pile of overlapping exceptions.

## Player-Facing Behavior
1. Enemies approach the player from navigation space until they reach acceptable melee range.
2. Once in acceptable melee range, an enemy should mostly hold position and face the player.
3. An enemy already in acceptable melee range should not keep searching for a better nearby point.
4. If the player moves away enough, the enemy should leave hold and approach again.
5. If the enemy remains in acceptable melee range, physical nudges alone should not trigger continual replanning.

## Interaction Rules

### Enemy vs Enemy
1. Enemies should physically collide with each other.
2. Rear enemies should reach the player by navigating into open space, not by shoving frontline enemies forward.
3. Frontline enemies must not behave like rigid wall elements under player pressure.
4. Frontline enemies must also not slide around continuously once already settled in melee.

### Player vs Enemy
1. The player should be able to push enemies somewhat.
2. Player push should create limited physical give, not fully immovable enemies.
3. Player push should not cause engaged melee enemies to vibrate or continually recalculate movement.

### Allowed Crowd Motion Near The Player
1. Sideways crowd flow is allowed.
2. Slight outward give is allowed.
3. Inward crowd-driven compression toward the player's center is not desirable.
4. Near the player, crowd interaction should mostly resolve sideways, not by crushing enemies deeper inward.

## Behavioral Bands

### 1. Approach
Enemy is outside melee range and still trying to get in.

Allowed behavior:
- navigation-driven approach
- engage-goal or direct chase
- bounded candidate selection around the player

Not desired:
- full-frame repathing
- random angle churn

### 2. Close Adjust
Enemy is near the player, but not yet stably in melee hold.

Allowed behavior:
- slow final approach
- local sideways adjustment
- collision-based crowd interaction

Rules:
- do not repeatedly resample nearby ring points in this band
- do not keep replacing a close-range goal every few tenths of a second
- prefer local steering over repeated fresh goal ownership

### 3. Melee Hold
Enemy is inside acceptable melee range.

Allowed behavior:
- hold position
- face the player
- slight physical displacement from player/enemy collision

Rules:
- do not actively reposition unless the enemy actually leaves the acceptable melee envelope
- do not let small nudges turn into visible locomotion churn
- do not let loss of cached goal ownership alone break hold

## Spreading Policy
1. Use soft spreading, not hard slot locking as the default.
2. Spreading should reduce obvious clumping, not force a perfect surround.
3. Candidate choice may consider path length, occupancy, and local crowding.
4. Path length should remain the dominant scoring term when candidate scoring is used.
5. Candidate scoring is appropriate mainly during approach, not as a constantly active near-player solver.

## Replanning Rules
Replanning is allowed when:
1. the player moved meaningfully
2. the enemy left acceptable melee range
3. the current goal became truly invalid
4. progress failure is large enough and sustained enough to justify a new plan

Replanning is not allowed when:
1. the enemy is still in acceptable melee range
2. the enemy only experienced a tiny local displacement
3. a cached goal was lost but the actual melee state is still valid
4. another nearby valid point merely looks slightly better

## Stuck and Recovery Policy
1. Stuck detection should still exist.
2. Recovery should improve the situation rather than retrying the same failing local choice.
3. Recovery should be more willing to replan far from the player than near the player.
4. Near the player, recovery should first prefer local resolution over goal churn.
5. Visible jitter in melee is a correctness failure, not an acceptable recovery side effect.

## Recommended Runtime Structure
Use a small explicit state machine:
1. `approach`
2. `close_adjust`
3. `melee_hold`

Recommended rules:
1. `melee_hold` should be defined by actual target distance and envelope checks, not by cached goal existence.
2. Goal selection should mainly serve `approach`.
3. `close_adjust` should be local and simple.
4. `melee_hold` should suppress unnecessary replanning.
5. Near the player, local interaction should be lateral-first.

## What Is Technically Reasonable
1. Soft spreading around the player is reasonable.
2. Minor physical shuffling in crowds is reasonable.
3. Bounded path-length-aware candidate choice is reasonable.
4. Sideways give-way behavior under compression is reasonable.
5. Stable melee hold with very little local motion is reasonable and desirable.

## What Is Not The Preferred Solution
1. Hard invisible rings around the player.
2. Completely rigid no-push enemies.
3. Constant near-player ring resampling.
4. Full crowd-simulation complexity for this slice.
5. Complex reservation systems unless a simpler rebuild fails first.

## Acceptance Criteria
1. A single enemy can enter melee range and stand stably without visible vibration.
2. Multiple enemies can gather near the player without constant slot-swapping.
3. The player can push enemies somewhat.
4. Enemy crowds resolve mostly by navigation, local spacing, and limited lateral give instead of enemy-on-enemy pushing.
5. Near-player crowd motion does not collapse into frantic inward compression.
6. Enemies already in melee range do not continually replan.
7. If the player moves away, enemies resume approach cleanly.

## Implementation Guidance
1. Keep debug and profiling separate from core movement decisions.
2. Keep close-range movement policy readable enough to reason about from logs.
3. Add debug that distinguishes:
   - state transitions
   - goal changes
   - local crowd adjustments
   - stuck-triggered replans
4. Treat any visible end-state vibration as a bug to remove, not as tuning noise.
