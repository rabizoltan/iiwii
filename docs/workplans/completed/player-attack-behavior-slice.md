# Player Attack Behavior Slice

## Status
- `completed`

## Current Role
- Historical delivery record for the player attack baseline slice.
- Exact current attack behavior should now be read from [combat.md](d:/Game/DEV/iiWii/iiwii/docs/systems/combat.md), [validation-map.md](d:/Game/DEV/iiWii/iiwii/docs/technical/validation-map.md), and [code-map.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/code-map.md).
- This document preserves the slice scope, execution order, and delivery-time acceptance context.

## Goal
Implement the intended baseline player attack behavior on top of the current foundation slice.

## Why This Is Separate
- The current projectile attack only proves that combat can exist.
- This slice turns the attack into the intended baseline player-facing behavior.

## Step Status Board
- Step 0 - Lock behavior rules: `completed`
- Step 1 - Mouse/world aim target resolution: `completed`
- Step 2 - Attack gating and no-fire rules: `completed`
- Step 3 - Projectile direction and impact resolution: `completed`
- Step 4 - Validation pass: `completed`

## Delivery-Time Baseline
The exact runtime truth now lives in [combat.md](d:/Game/DEV/iiWii/iiwii/docs/systems/combat.md). The rules below are the slice-specific baseline that was locked for delivery:

1. Baseline firing mode is single-click single-shot.
2. Baseline cooldown is `0.5` second.
3. Baseline shots do not pierce.
4. Projectile range is unlimited for this slice.
5. Projectile speed is not a locked design constant for this slice yet.
6. Valid aim targets are:
   - enemies
   - ground
   - obstacles
7. The player cannot aim at self.
8. If there is no valid target under the cursor, the player does not shoot.
9. If the cursor is on ground, the projectile should resolve to that aimed ground point.
10. If the cursor is on an enemy, the projectile should resolve to that enemy.
11. If the cursor is on an obstacle, the projectile should resolve to that obstacle.
12. Ground-targetable shots must work for elevated shots and for targeting ground between enemies.
13. Intended feel is deliberate aimed shooting:
   - not blind bullet-hell spam
   - not extremely slow long-delay shooting

## Execution Order

### Step 0 - Lock Behavior Rules
Status: `completed`

Actions:
1. Read the combat source-of-truth docs and ADR input/aim rules.
2. Record baseline cadence, aiming, and impact behavior in this slice plan.
3. Record the agreed no-fire and non-piercing defaults.

Exit gate:
- The implementation task can proceed without guessing attack behavior.

### Step 1 - Mouse/World Aim Target Resolution
Status: `completed`

Actions:
1. Add cursor-to-world aim resolution in the player attack flow.
2. Resolve a valid target point from:
   - enemy
   - ground
   - obstacle
3. Ignore self as a valid aim target.
4. Ensure the resolved aim point works from elevated positions as well as flat ground.

Exit gate:
- The player can produce a valid world aim target from the cursor.

### Step 2 - Attack Gating And No-Fire Rules
Status: `completed`

Actions:
1. Enforce single-click single-shot behavior.
2. Enforce `0.5s` cooldown.
3. Do not fire if no valid aim target exists under the cursor.
4. Keep attack direction independent from movement direction.

Exit gate:
- Input and cooldown behavior match the agreed baseline.

### Step 3 - Projectile Direction And Impact Resolution
Status: `completed`

Actions:
1. Fire projectiles from player chest toward the resolved aim target.
2. Keep baseline shots non-piercing.
3. Make impacts resolve correctly against:
   - enemies
   - ground
   - obstacles
4. Preserve unlimited range for the slice unless collision ends the shot first.

Exit gate:
- Shot travel and impact resolution match the agreed targeting rules.

### Step 4 - Validation Pass
Status: `completed`

Actions:
1. Validate enemy targeting.
2. Validate ground targeting.
3. Validate obstacle targeting.
4. Validate no-fire on invalid target.
5. Validate elevated-to-lower-ground targeting.
6. Check that the feel is deliberate, readable, and not spammy.

Current demo-scene fixtures:
- stationary target dummy near player start
- reachable elevated shooting platform with ramp for downward shot validation

Exit gate:
- The slice behavior is validated in the demo scene.

## Success Criteria
1. Player attacks use mouse/world aim instead of movement-facing aim.
2. One click produces one shot.
3. `0.5s` cooldown is enforced.
4. Projectiles do not pierce by default.
5. If the cursor is on ground, the shot resolves to the aimed ground point.
6. If the cursor is on an enemy, the shot resolves to that enemy.
7. If the cursor is on an obstacle, the shot resolves to that obstacle.
8. If there is no valid aim target under the cursor, no shot is fired.
9. Shooting from elevated positions still respects the same aim rule.

## Non-Goals
- no piercing extension yet
- no burst or hold-to-fire mode
- no final projectile speed tuning
- no combat feedback pass in this slice
- no melee enemy behavior tuning in this slice

## Dependencies
- [combat.md](d:/Game/DEV/iiWii/iiwii/docs/systems/combat.md)
- [ADR-007-input-and-controls.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-007-input-and-controls.md)
- [ADR-016-space-model-continuous-world-navmesh-no-tile-diagonals.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-016-space-model-continuous-world-navmesh-no-tile-diagonals.md)

## Historical Next Slice Note
After this slice was implemented and validated, the intended follow-on was:
- [debug-control-panel-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/completed/debug-control-panel-slice.md)
- [enemy-close-range-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/stale/enemy-close-range-behavior-slice.md)

For the current planning entry point, read [behavior-slice-roadmap.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/roadmaps/behavior-slice-roadmap.md).
