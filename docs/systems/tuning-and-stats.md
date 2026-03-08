# Tuning And Stats

This document defines the intended ownership and organization of gameplay tuning data.

## Purpose
- Keep gameplay numbers centralized enough to tune safely.
- Separate tunable values from hard-coded combat or movement logic over time.

### Movement Fields
- `move_speed`
- `acceleration`
- `deceleration`
- `camera_relative_movement`
- `crouch_speed`
- `crouch_speed_mult`
- `vault_duration`
- `vault_default_distance`
- `vault_min_distance`
- `vault_max_distance`
- `vault_clearance`
- `vault_min_height`
- `vault_max_height`
- `dodge_duration`
- `dodge_distance`
- `dodge_speed`
- `dodge_cooldown`
- `dodge_iframes_start`
- `dodge_iframes_end`

## Player Combat/Health Constants
- If these remain code-owned early, keep them grouped clearly:
  - `ATTACK_DAMAGE`
  - `ATTACK_RANGE`
  - `MELEE_DAMAGE`
  - `MELEE_COOLDOWN`
  - `MELEE_FORWARD_OFFSET`
  - `MAX_HP`
  - ray masks/ray length values for targeting

If broader tuning unification is needed, move these to a dedicated combat resource.

## Enemy Stats And Behavior Tuning

### Suggested Exported Enemy Stats
- `move_speed`
- `aggro_range`
- `stop_range`
- `attack_windup`
- `attack_cooldown`
- `attack_damage`
- `max_hp`
- `stagger_on_hit`

## New Enemy Tuning Workflow
1. Start from the shared base enemy tuning set.
2. Change only the values that define role differences.
3. Validate navigation and combat behavior in the current gameplay test scenario.

## Safe Tuning Workflow
1. Change one variable cluster at a time (speed, then dodge, then vault).
2. Run the current gameplay test scene and validate the focused behavior.
3. Validate no lock-state regressions:
   - crouch release recovery
   - dodge end-state recovery
   - vault entry only near valid obstacles
4. Keep i-frame window within `[0, 1]` normalized dodge progress.

## Notes
- Intended early tuning split:
  - movement values grouped together
  - combat and enemy values grouped together
- This is intentional for incremental migration without large refactors.
