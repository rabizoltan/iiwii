# Enemy Navigation Audit - Implementation Backlog

## Scope
This document captures the enemy-navigation issues that should be implemented later.
Focus: enemy pathing quality, wall/corner unstuck reliability, narrow-space correctness, and stable player following.

## Status
- `blocked`

Reason:
- The repository currently contains design documentation only.
- The gameplay scripts, scenes, and tuning assets referenced by the original version of this plan are not present here yet.
- Treat this file as a backlog of intended fixes, not as an active implementation record.

## Critical Findings
1. Navigation agent radius/layer mismatch with enemy collider.
2. Missing LOS gate in attack state transitions.
3. Goal selection uses rotating or random offsets instead of path-dominant reachable candidate scoring.
4. Missing unreachable-target anchor workflow.
5. Possible spawner collision mask overwrite bug.
6. Stuck recovery is not a full escalation ladder.
7. Path/arrival tolerances may be too permissive for tight geometry.

## Implementation Preconditions
Before this backlog becomes active, the repo should contain:
1. Enemy runtime scripts for movement, navigation, and combat.
2. Enemy scenes with collider and `NavigationAgent3D` setup.
3. A navigation testbed scene for narrow corridors, corner wedges, and LOS blockers.
4. A confirmed file layout that matches the implementation docs.

## Proposed Work Slices
These slices remain valid as design guidance, but they should only be mapped to real files after the codebase exists.

### Slice 0 - Immediate Hotfixes
#### 0.1 Fix collision mask overwrite in spawner
- Target: enemy spawner runtime script
- Problem: collision mask may be overwritten instead of combined.
- Action: combine masks properly for world and enemy collision.

#### 0.2 Align NavigationAgent radius to real body collider
- Target: enemy scene plus runtime setup script
- Action:
  - read collider radius from body collision shape or config
  - set `nav_agent.radius` from collider radius with a small safety multiplier
- Expected effect: fewer wall clips and fewer failed entries in narrow passages.

#### 0.3 Reduce over-loose path tolerances
- Target: enemy movement/navigation runtime script
- Action:
  - retune `path_desired_distance` and `target_desired_distance` for tighter corner tracking
  - keep stop range consistent with combat design
- Expected effect: less premature finished-path state.

### Slice 1 - Behavior Correctness
#### 1.1 Add LOS gate to engage/attack
- Target: enemy combat state logic
- Action:
  - add raycast-based LOS check before windup or attack transitions
  - if no LOS, remain in chase or reposition state
- Expected effect: no wall-hitting behavior and better pursuit decisions.

#### 1.2 Introduce reachable anchor for unreachable targets
- Target: enemy navigation logic
- Action:
  - if target position is unreachable for current nav layers, compute anchor and pursue around anchor
  - do not drop target solely for unreachable path
- Expected effect: stable pursuit instead of random fallback near blocked geometry.

#### 1.3 Replace rotating offset targeting with candidate scoring
- Target: goal-selection logic
- Action:
  - generate ring candidates around player or anchor
  - validate candidate reachability
  - score with path length as the dominant term
- Expected effect: less orbiting and more direct pursuit.

### Slice 2 - Robustness For Crowd And Corners
#### 2.1 Implement real stuck recovery ladder
- Target: enemy navigation recovery logic
- Action:
  1. re-pick goal excluding recent failed candidates
  2. local detour waypoint
  3. temporary widening of movement constraints
  4. anti-clump bias
- Expected effect: no long-lived wedge deadlocks.

#### 2.2 Size-class nav layer correctness
- Target: enemy setup and config layer mapping
- Action:
  - derive exactly one nav size bit per enemy type
  - ensure no invalid traversal through lanes intended for smaller classes
- Expected effect: large enemies stop attempting impossible corridors.

### Slice 3 - Instrumentation And Validation
#### 3.1 Debug counters
- Add counters per enemy:
  - `repath_count`
  - `stuck_count`
  - `goal_changes`
  - `target_switches`
  - `los_fail_count`

#### 3.2 Test execution against documented fixtures
- Validate against [enemy-ai-testplan-v1.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/ai/enemy-ai-testplan-v1.md)
- Mandatory pass focus:
  - corner wedge recovery
  - mixed size/layer correctness
  - unreachable target anchor behavior
  - no per-frame repath at scale

## Acceptance Criteria
- Enemy does not stay pinned for long in corner-wedge cases.
- No attack transition without LOS.
- Path quality improves in narrow environments.
- Large enemies avoid small-only corridors.
- Repath frequency remains bounded and not per-frame.

## Repository Note
- The original version of this document referenced specific `godot/...` file paths and implied that some fixes were ready to execute immediately.
- Those path references were removed because the files are not present in this repository today.
- Reintroduce concrete file paths only after the gameplay project structure exists here.

## Rollout Recommendation
1. Start with Slice 0 once runtime assets exist.
2. Follow with Slice 1 after baseline validation.
3. Merge Slice 2 and Slice 3 only after fixture-based test coverage is real.
