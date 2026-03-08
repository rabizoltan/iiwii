# Enemy Navigation & Player Follow Audit - Implementation Plan

## Scope
This plan translates the navigation audit findings into an executable implementation sequence.
Focus: enemy pathing quality, wall/corner unstuck reliability, narrow-space correctness, and stable player following.

## Critical Findings (from audit)
1. Navigation agent radius/layer mismatch with enemy collider.
2. Missing LOS gate in attack state transitions.
3. Goal selection uses rotating/random offsets instead of path-dominant reachable candidate scoring.
4. Missing unreachable-target anchor workflow.
5. Spawner collision mask overwrite bug.
6. Stuck recovery is not a full escalation ladder.
7. Path/arrival tolerances are too permissive for tight geometry.

## Phase 0 - Immediate Hotfixes (same day)
### 0.1 Fix collision mask overwrite in spawner
- File: `godot/scripts/gameplay/spawners/enemy_spawner.gd`
- Current bug: collision mask is overwritten (`1` then `4`).
- Action: combine masks properly (world + enemy), avoid destructive reassignment.
- Risk: low.

### 0.2 Align NavigationAgent radius to real body collider
- Files:
  - `godot/scenes/gameplay/enemies/EnemyBasic.tscn`
  - `godot/scripts/gameplay/enemies/enemy_basic.gd`
- Action:
  - Read collider radius from `BodyCollision` shape (or exported per-enemy config).
  - Set `nav_agent.radius` to `capsule_radius * 1.10..1.20`.
- Expected effect: fewer wall clips and fewer failed entries in narrow passages.

### 0.3 Reduce over-loose path tolerances
- File: `godot/scripts/gameplay/enemies/enemy_basic.gd`
- Action:
  - Re-tune `path_desired_distance` and `target_desired_distance` for tighter corner tracking.
  - Keep stop range consistent with combat design.
- Expected effect: less premature "finished" path state.

## Phase 1 - Behavior Correctness (1-2 days)
### 1.1 Add LOS gate to engage/attack
- File: `godot/scripts/gameplay/actors/enemies/enemy_combat_fsm.gd`
- Add raycast-based LOS check before WINDUP/ATTACK transitions.
- If no LOS: remain in chase/reposition state.
- Expected effect: no wall-hitting behavior and better pursuit decisions.

### 1.2 Introduce reachable anchor for unreachable targets
- Files:
  - `godot/scripts/gameplay/actors/enemies/enemy_navigation.gd`
  - `godot/scripts/gameplay/enemies/enemy_basic.gd`
- Action:
  - If target position is unreachable for current nav layers, compute anchor and pursue around anchor.
  - Do not drop target solely for unreachable path.
- Expected effect: stable pursuit instead of random fallback near blocked geometry.

### 1.3 Replace rotating offset targeting with candidate scoring
- Files:
  - `godot/scripts/gameplay/actors/enemies/enemy_navigation.gd`
  - `godot/scripts/gameplay/enemies/enemy_basic.gd`
- Action:
  - Generate ring candidates (melee) around center (player or anchor).
  - Validate candidate reachability.
  - Score with path length as dominant term.
- Expected effect: less orbiting/far-side pathing, more direct and believable chase.

## Phase 2 - Robustness for Crowd/Corners (2-3 days)
### 2.1 Implement real stuck recovery ladder
- File: `godot/scripts/gameplay/actors/enemies/enemy_navigation.gd`
- Steps:
  1. Re-pick goal excluding recent failed candidates.
  2. Local detour waypoint.
  3. Temporary widening of movement constraints.
  4. Anti-clump bias.
- Add cooldown + escalation state reset on successful progress.
- Expected effect: no long-lived wedge deadlocks.

### 2.2 Size-class nav layer correctness
- Files:
  - `godot/scripts/gameplay/enemies/enemy_basic.gd`
  - optional config resource file(s)
- Action:
  - Derive/set one nav size bit per enemy type.
  - Ensure no invalid traversal through lanes intended for smaller classes.
- Expected effect: large enemies stop attempting impossible corridors.

## Phase 3 - Instrumentation & Validation (parallel)
### 3.1 Debug counters
- Add counters per enemy:
  - `repath_count`, `stuck_count`, `goal_changes`, `target_switches`, `los_fail_count`
- Expose in current debug overlay.

### 3.2 Test execution against documented fixtures
- Validate against:
  - `docs/architecture/ai/enemy-ai-testplan-v1.md`
- Mandatory pass focus:
  - Corner wedge recovery
  - Mixed size/layer correctness
  - Unreachable target anchor behavior
  - No per-frame repath at scale

## Acceptance Criteria
- Enemy does not stay pinned > 3s in corner wedge cases.
- No attack transition without LOS.
- Path quality improves in narrow environments (observable reduction in wall-sticking).
- Large enemies avoid small-only corridors.
- Repath frequency remains bounded and not per-frame.

## File Impact (expected)
- `godot/scripts/gameplay/spawners/enemy_spawner.gd`
- `godot/scripts/gameplay/enemies/enemy_basic.gd`
- `godot/scripts/gameplay/actors/enemies/enemy_navigation.gd`
- `godot/scripts/gameplay/actors/enemies/enemy_combat_fsm.gd`
- optional tuning/config resources under `godot/resources/tuning/`

## Rollout Recommendation
1. Ship Phase 0 as hotfix branch first.
2. Ship Phase 1 behind a runtime debug toggle if needed.
3. Merge Phase 2 after testplan fixture pass.
