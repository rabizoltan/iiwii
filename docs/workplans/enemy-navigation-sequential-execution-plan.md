# Enemy Navigation - Sequential Execution Plan

## Goal
Provide a safe execution order for enemy-navigation implementation once the gameplay codebase exists in this repository.

## Status
- `blocked`

Reason:
- This repository currently does not contain the `godot/` code tree, scenes, scripts, or testbeds referenced by the original plan.
- Any earlier wording that implied completed implementation steps in this repo was inaccurate and has been removed.

## Activation Prerequisites
This plan becomes executable only when all of the following exist in the repo:
1. A gameplay code tree with enemy navigation/combat scripts.
2. Enemy scenes and at least one navigation testbed scene.
3. Runtime debug tooling or equivalent logging hooks.
4. A clear mapping from architecture docs to actual file paths.

Until then, this document should be treated as sequencing guidance only.

## Step Status Board
- [ ] Step 1 - Baseline freeze and instrumentation check
- [ ] Step 2 - Critical hotfix: collision mask overwrite
- [ ] Step 3 - Critical hotfix: nav radius and layer alignment
- [ ] Step 4 - Movement stability tuning
- [ ] Step 5 - Combat correctness: LOS attack gate
- [ ] Step 6 - Navigation correctness: unreachable target anchor
- [ ] Step 7 - Goal selection refactor: replace rotating offset
- [ ] Step 8 - Stuck recovery ladder implementation
- [ ] Step 9 - Size-class and capability validation pass
- [ ] Step 10 - Performance and scheduling hardening
- [ ] Step 11 - Full regression run against AI test plan

## Execution Rules
- Do not mix unrelated feature additions into the same slice.
- Validate after each step before proceeding.
- Keep changes small and reversible.
- Stop progression if a gate fails.

## Step-by-Step Order

### Step 1 - Baseline freeze and instrumentation check
Why first: no reliable baseline means no objective progress tracking.

Actions:
1. Record current behavior in existing testbed scenes for corner wedge, narrow corridor, and mixed-size cases.
2. Enable debug overlay or equivalent logging and collect baseline numbers:
   - stuck frequency
   - repath frequency
   - average time-to-engage
3. Save baseline notes in project docs.

Exit gate:
- Baseline metrics and repro cases are documented.

### Step 2 - Critical hotfix: collision mask overwrite
Dependency: Step 1 complete.

Actions:
1. Fix spawner collision-mask assignment bug in the actual spawner script so world and enemy masks are both active.
2. Verify spawned enemies collide with static world and with other enemies as intended.

Exit gate:
- Spawned enemies no longer lose world collision.
- No regression in spawn flow.

### Step 3 - Critical hotfix: nav radius and layer alignment
Dependency: Step 2 complete.

Actions:
1. Align `NavigationAgent3D.radius` to real body collider radius with a small safety multiplier.
2. Stop hardcoding a single nav layer for all enemies; set proper size-based nav layer.
3. Ensure enemy starts snapped to a valid nav map point for its layer.

Exit gate:
- Large enemies stop attempting clearly too-tight routes.
- Narrow-space failures reduce in baseline repro scenes.

### Step 4 - Movement stability tuning
Dependency: Step 3 complete.

Actions:
1. Retune `path_desired_distance` and `target_desired_distance` to reduce corner shortcut artifacts.
2. Verify no excessive stop-and-go oscillation.
3. Validate no sudden performance spikes from tuning changes.

Exit gate:
- Fewer false `navigation_finished` states.
- Path tracking near corners is visibly tighter.

### Step 5 - Combat correctness: LOS attack gate
Dependency: Step 4 complete.

Actions:
1. Add LOS check into combat state transitions before windup/attack.
2. If LOS fails, enemy remains in chase/reposition instead of attacking.
3. Add debug marker or counter for LOS-failed attack attempts.

Exit gate:
- No attacks through walls in LOS blocker scenarios.
- Engagement remains responsive when LOS is valid.

### Step 6 - Navigation correctness: unreachable target anchor
Dependency: Step 5 complete.

Actions:
1. Implement anchor selection for unreachable player positions.
2. Continue pursuit via nearest reachable anchor instead of dropping/fallback drifting.
3. Ensure anchor updates are throttled rather than per-frame.

Exit gate:
- Enemy keeps target and moves to meaningful reachable positions.
- Unreachable target scenario passes behaviorally.

### Step 7 - Goal selection refactor: replace rotating offset
Dependency: Step 6 complete.

Actions:
1. Replace rotating random offset targeting with candidate-based goal selection.
2. Implement melee ring candidate generation around player or anchor center.
3. Score candidates with a path-length-dominant function.
4. Keep soft occupancy penalty optional but supported.

Exit gate:
- Reduced far-side orbiting.
- More consistent direct pursuit and surround behavior.

### Step 8 - Stuck recovery ladder implementation
Dependency: Step 7 complete.

Actions:
1. Add explicit multi-step recovery ladder:
   - re-pick goal excluding recent failed points
   - local detour waypoint
   - temporary constraint widening
   - anti-clump bias
2. Add cooldown and escalation reset on successful progress.
3. Add recovery-step debug output.

Exit gate:
- Corner wedge case resolves without long pinning.
- No repeated loop on the same failed local behavior.

### Step 9 - Size-class and capability validation pass
Dependency: Step 8 complete.

Actions:
1. Ensure each enemy uses exactly one size nav bit.
2. Validate capability bits are separated from size bits.
3. Confirm scene/navigation data matches runtime assumptions.

Exit gate:
- Mixed-size test shows correct traversal permissions.
- No cross-layer leakage.

### Step 10 - Performance and scheduling hardening
Dependency: Step 9 complete.

Actions:
1. Ensure repath/goal/target updates are timer-driven and staggered.
2. Validate behavior under high active-enemy counts.
3. Prevent per-frame repath patterns.

Exit gate:
- Stable frame behavior in a stress scene.
- Debug counters show bounded update rates.

### Step 11 - Full regression run against AI test plan
Dependency: Step 10 complete.

Actions:
1. Run all scenarios in [enemy-ai-testplan-v1.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/ai/enemy-ai-testplan-v1.md).
2. Document pass/fail and residual risks.
3. Fix blockers before merge.

Exit gate:
- Mandatory scenarios pass:
  - corner wedge recovery
  - mixed sizes/layers
  - unreachable target anchor
  - LOS attack gating

## Deliverables Checklist
- [ ] Updated runtime code for nav/combat/spawn systems
- [ ] Updated tuning values and size/layer mapping
- [ ] Debug counters and overlay fields
- [ ] Test report with scenario-by-scenario results
- [ ] Final residual risk notes

## Stop Conditions
Pause rollout if any of these occurs:
- New collision regressions after Steps 2-3.
- Repath spikes after Step 10.
- Corner wedge still fails after Step 8.
- LOS gate causes non-engaging enemies in open spaces.
