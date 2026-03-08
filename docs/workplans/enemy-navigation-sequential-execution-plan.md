# Enemy Navigation - Sequential Execution Plan

## Goal
Deliver a stable enemy navigation and player-follow behavior with predictable corner recovery, correct size-based traversal, and combat engagement quality.

## Progress Status
- Current focus: Step 3 - Critical hotfix: nav radius and layer alignment
- Last completed step: Step 2 - Critical hotfix: collision mask overwrite
- Completion notes:
  - Fixed in `godot/scripts/gameplay/spawners/enemy_spawner.gd`
  - Replaced destructive collision mask assignment with explicit layer/mask value setup.

## Step Status Board
- [ ] Step 1 - Baseline freeze and instrumentation check
- [x] Step 2 - Critical hotfix: collision mask overwrite
- [ ] Step 3 - Critical hotfix: nav radius and layer alignment
- [ ] Step 4 - Movement stability tuning (non-feature)
- [ ] Step 5 - Combat correctness: LOS attack gate
- [ ] Step 6 - Navigation correctness: unreachable target anchor
- [ ] Step 7 - Goal selection refactor: replace rotating offset
- [ ] Step 8 - Stuck recovery ladder implementation
- [ ] Step 9 - Size-class and capability validation pass
- [ ] Step 10 - Performance and scheduling hardening
- [ ] Step 11 - Full regression run against AI test plan
- [ ] Step 12 - Merge strategy and rollout

## Execution Rules
- Do not run feature additions and cleanup in the same slice.
- Validate after each step before proceeding.
- Keep changes small and reversible.
- Stop progression if a gate fails.

## Step-by-Step Order

### Step 1 - Baseline freeze and instrumentation check
**Why first:** no reliable baseline -> no objective progress tracking.

Actions:
1. Record current behavior in testbed scenes (corner wedge, narrow corridor, mixed sizes).
2. Enable current debug overlay and collect baseline numbers:
   - stuck frequency
   - repath frequency
   - average time-to-engage
3. Save baseline notes in project docs.

Exit gate:
- Baseline metrics and repro cases are documented.

---

### Step 2 - Critical hotfix: collision mask overwrite
**Dependency:** Step 1 complete.

Actions:
1. Fix spawner collision-mask assignment bug in `enemy_spawner.gd` so world + enemy masks are both active.
2. Verify spawned enemies collide with static world and with other enemies as intended.

Exit gate:
- Spawned enemies no longer lose world collision.
- No regression in spawn flow.

---

### Step 3 - Critical hotfix: nav radius and layer alignment
**Dependency:** Step 2 complete.

Actions:
1. Align `NavigationAgent3D.radius` to real body collider radius (with small safety multiplier).
2. Stop hardcoding a single nav layer for all enemies; set proper size-based nav layer.
3. Ensure enemy starts snapped to valid nav map point for its layer.

Exit gate:
- Large enemies stop attempting clearly too-tight routes.
- Narrow-space failures reduce in baseline repro scenes.

---

### Step 4 - Movement stability tuning (non-feature)
**Dependency:** Step 3 complete.

Actions:
1. Retune `path_desired_distance` and `target_desired_distance` to reduce corner shortcut artifacts.
2. Verify no excessive stop-and-go oscillation.
3. Validate no sudden performance spikes from tuning changes.

Exit gate:
- Fewer false `navigation_finished` states.
- Path tracking near corners is visibly tighter.

---

### Step 5 - Combat correctness: LOS attack gate
**Dependency:** Step 4 complete.

Actions:
1. Add LOS check into combat state transitions before windup/attack.
2. If LOS fails, enemy remains in chase/reposition instead of attacking.
3. Add debug marker/counter for LOS-failed attack attempts.

Exit gate:
- No attacks through walls in LOS blocker scenarios.
- Engagement remains responsive when LOS is valid.

---

### Step 6 - Navigation correctness: unreachable target anchor
**Dependency:** Step 5 complete.

Actions:
1. Implement anchor selection for unreachable player positions.
2. Continue pursuit via nearest reachable anchor instead of dropping/fallback drifting.
3. Ensure anchor updates are throttled (not per-frame).

Exit gate:
- Enemy keeps target and moves to meaningful reachable positions.
- Unreachable target test scenario passes behaviorally.

---

### Step 7 - Goal selection refactor: replace rotating offset
**Dependency:** Step 6 complete.

Actions:
1. Replace rotating random offset targeting with candidate-based goal selection.
2. Implement melee ring candidate generation around center (player or anchor).
3. Score candidates with path-length-dominant function.
4. Keep soft occupancy penalty optional but supported.

Exit gate:
- Reduced far-side orbiting.
- More consistent direct pursuit and surround behavior.

---

### Step 8 - Stuck recovery ladder implementation
**Dependency:** Step 7 complete.

Actions:
1. Add explicit multi-step recovery ladder:
   - re-pick goal excluding recent failed points
   - local detour waypoint
   - temporary constraint widening
   - anti-clump bias
2. Add cooldown and escalation reset on successful progress.
3. Add recovery step debug output.

Exit gate:
- Corner wedge case resolves without long pinning.
- No repeated loop on the same failed local behavior.

---

### Step 9 - Size-class and capability validation pass
**Dependency:** Step 8 complete.

Actions:
1. Ensure each enemy uses exactly one size nav bit.
2. Validate capability bits are separated from size bits.
3. Confirm scene/navigation data matches runtime assumptions.

Exit gate:
- Mixed-size test shows correct traversal permissions.
- No cross-layer leakage.

---

### Step 10 - Performance and scheduling hardening
**Dependency:** Step 9 complete.

Actions:
1. Ensure repath/goal/target updates are timer-driven and staggered.
2. Validate behavior under 100 active enemies.
3. Prevent per-frame repath patterns.

Exit gate:
- Stable frame behavior in stress scene.
- Debug counters show bounded update rates.

---

### Step 11 - Full regression run against AI test plan
**Dependency:** Step 10 complete.

Actions:
1. Run all scenarios in `docs/architecture/ai/enemy-ai-testplan-v1.md`.
2. Document pass/fail and residual risks.
3. Fix blockers before merge.

Exit gate:
- Mandatory scenarios pass:
  - corner wedge recovery
  - mixed sizes/layers
  - unreachable target anchor
  - LOS attack gating

---

### Step 12 - Merge strategy and rollout
**Dependency:** Step 11 complete.

Actions:
1. Merge in controlled slices:
   - Slice A: Steps 2-4 (hotfix + stability)
   - Slice B: Steps 5-7 (combat/nav correctness)
   - Slice C: Steps 8-10 (robustness + scaling)
2. Keep debug counters enabled in QA builds.
3. Post-merge monitor known hotspots.

Exit gate:
- Production branch contains validated slices with documented behavior changes.

## Deliverables Checklist
- [ ] Updated runtime code for nav/combat/spawn systems
- [ ] Updated tuning values and size/layer mapping
- [ ] Debug counters and overlay fields
- [ ] Test report with scenario-by-scenario results
- [ ] Final residual risk notes

## Suggested Ownership Split
- Engineer A: spawner + nav core + stuck ladder
- Engineer B: combat FSM + LOS + goal scoring
- Designer/Tech Designer: tuning pass + acceptance scene validation

## Stop Conditions
Pause rollout if any of these occurs:
- New collision regressions after Step 2-3.
- Repath spikes after Step 10.
- Corner wedge still fails after Step 8.
- LOS gate causes non-engaging enemies in open spaces.
