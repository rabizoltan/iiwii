# Enemy AI Navigation v1

## Status
- Partially implemented.
- The melee close-range target behavior is now documented explicitly in [enemy-melee-behavior-v1.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/ai/enemy-melee-behavior-v1.md).
- The current runtime implementation should be treated as rebuild work against that contract, not as final reference behavior.
- Threat-table target selection, ranged donut/kite behavior, LOS attack gating, unreachable-anchor handling, multi-size nav-layer authoring, and the broader v1 test fixture set remain design targets.

## Summary
Implement a robust enemy navigation and combat-positioning system for up to roughly 100 enemies.

Enemies pick the highest-threat player and move toward a goal point near that player:
- melee: ring gather close enough to engage
- ranged: donut positioning with LOS-based peeking and strafing kite behavior

The system must avoid common corner-wedge stuck cases with explicit stuck detection and recovery.

## Goals
1. Target the player with the highest threat. In v1, threat can be distance-only.
2. Melee enemies gather around the target, hold at engage distance, and attempt to hit.
3. Ranged enemies maintain a preferred distance band and kite via strafing while keeping LOS.
4. Enemies stay separated enough to avoid permanent blocking.
5. Recovery around obstacles and corners must be robust.
6. Scale to around 100 active enemies without per-frame repaths or visible jitter.

## Non-goals
- advanced squad tactics or formations
- runtime navmesh cutting or carving
- expensive multi-agent global optimization

## Key Constraints and Assumptions
- target multiplayer model is host-authoritative
- target navigation setup uses 3 size layers:
  - `NavRegion_Small` using nav bit 1
  - `NavRegion_Medium` using nav bit 2
  - `NavRegion_Large` using nav bit 3
- all nav meshes bake from the same world geometry group: `"Navigation"`
- enemy sizes vary by capsule radius and height
- player traversal may allow spaces enemies cannot use, controlled through nav layers and capability links

## Architecture Overview

### Subsystems
- threat and target selection
- goal selection for melee ring or ranged donut
- LOS and attack gating
- locomotion with path following and separation
- stuck detection and recovery ladder
- tick scheduling to avoid spikes and jitter

### High-level enemy loop
- `AcquireTarget`
- `ChooseGoal`
- `MoveToGoal`
- `Engage`
- `StuckRecovery`

For the melee subset, the detailed close-range state model is:
- `approach`
- `close_adjust`
- `melee_hold`

## Threat and Target Selection

### Threat table
Per enemy, maintain a table keyed by `player_id`:
- `threat_value`
- `last_update_time`

### v1 threat formula
Compute on `THREAT_TICK_SEC`:
- `d = distance(enemy, player)`
- `threat = 1 / (d*d + eps)`

### Target hysteresis
Keep the current target unless:
- `new_threat >= THREAT_SWITCH_MULT * current_threat`

### Unreachable target behavior
Do not drop a target solely because it is unreachable.
Instead, compute a reachable anchor and continue pursuing through goal selection.

## Goal Selection

### Key idea
Enemies do not path to the raw player position.
They path to a nearby goal point chosen from candidates around the player or around an anchor if the player is unreachable.

Selection should prefer the closest reachable candidate by path length, not random angle.

### Shared definitions
- `P` = target player position
- `E` = enemy position
- `A` = reachable anchor position
- `Center` = `P` if reachable, otherwise `A`
- `C` = candidate point around `Center`
- `C_proj` = candidate projected to navmesh

### Anchor point
If the player is not on nav space reachable by this enemy:
- compute `A` as the closest reachable nav point to `P`
- center candidate generation on `A`

### Candidate generation
Melee:
- generate ring candidates around `Center`
- radius derives from attack range with clamps
- once at engage distance, hold rather than orbit or keep pressing inward
- if the player moves, re-acquire a nearby reachable engage point
- do not keep resampling nearby ring points as a continuously active solver once already near the player

Ranged:
- generate candidates inside a preferred distance band
- sampling can use rings or polar samples

### Candidate validation
A candidate is valid only if:
1. nav projection exists and projection distance is within tolerance
2. clearance check passes for the enemy size
3. a path exists to the candidate, if path validation is enabled

### Candidate scoring
Use a weighted score:
- path length
- occupancy penalty
- LOS penalty
- wall-proximity penalty
- turn-cost penalty

Rule:
- path length must dominate

### Soft occupancy
Maintain a lightweight occupancy metric near the target so enemies prefer less crowded points without hard slot locking.

Rule:
- use soft spreading only
- do not force a fast full surround of the player
- do not let occupancy logic destabilize already-settled melee enemies

### Commitment window
Keep a selected goal for a short commit window unless:
- target changes
- stuck triggers
- ranged behavior needs to reposition for LOS or distance
- player movement shifts the center significantly

## LOS and Attack Gating

### LOS raycast
Default:
- enemy chest or eye point to player chest point

Optional:
- second ray to player head

### Rules
- attacks require LOS
- movement may prefer LOS but should not require LOS

## Locomotion and Separation

### Path following
- use `NavigationAgent3D` path following toward the selected goal
- do not repath every frame
- repath only when:
  - goal changes
  - enough time has elapsed
  - agent deviates heavily from the path

### Separation
- use avoidance where possible
- keep physical collision so enemies can push slightly
- do not rely purely on physics pushing for crowd movement
- near the player, prefer lateral crowd flow over inward compression
- physical nudges alone should not force continual melee replanning

### Variable sizes
- clearance queries must use the real capsule size for each enemy
- avoidance radius should scale with capsule radius

## Stuck Detection and Recovery

### Stuck detection
Sample progress every `STUCK_SAMPLE_DT`:
- compare previous distance to goal vs current distance to goal
- accumulate stuck time when speed is low, distance is still meaningful, and progress is below threshold

Trigger stuck event when stuck time reaches threshold.

### Recovery ladder
On a stuck event, escalate:
1. re-pick goal and exclude recent failed candidates
2. add a local detour point
3. loosen movement constraints temporarily
4. apply anti-clump bias

Rule:
- never use "repath to the exact same goal" as the only response

## Tick Scheduling
Stagger updates per enemy:
- threat tick around `0.35s`
- goal-select tick around `0.85s`
- repath minimum interval around `0.6s`
- stuck sampling around `0.15s`

## Debug Requirements
When debug overlay is enabled, expose:
- current path
- current goal point
- optional candidate ring or donut only if it remains readable and trustworthy
- LOS ray and LOS bool
- per-enemy fields:
  - `target_player_id`
  - `goal_age`
  - `stuck_time`
  - `recovery_step`
  - `repath_count`
  - `goal_changes`
  - `target_switches`

For melee debugging specifically, logs should make it easy to separate:
- state transitions
- goal replacement
- local crowd-adjust movement
- stuck-triggered recovery
