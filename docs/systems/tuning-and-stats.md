# Tuning And Stats
Category: Gameplay System
Role: Reference Contract
Last updated: 2026-03-30
Last validated: pending

This document defines the intended ownership and organization of gameplay tuning data.

## Purpose
- Keep gameplay numbers centralized enough to tune safely.
- Separate tunable values from hard-coded combat or movement logic over time.

## Movement Fields
### Player-controller movement and traversal tuning
- `move_speed`
- `turn_speed`
- `crouch_speed_multiplier`
- `crouch_collision_height`
- `crouch_collision_center_y`
- `vault_duration`
- `vault_activation_distance`
- `vault_facing_angle_degrees`
- `vault_arc_min_height`
- `vault_arc_max_height`
- `vault_same_floor_tolerance`
- `dodge_distance`
- `dodge_duration`
- `dodge_cooldown`
- `dodge_enemy_ghost_start`
- `dodge_enemy_ghost_end`
- `dash_distance`
- `dash_duration`
- `dash_cooldown`
- `dash_enemy_ghost_start`
- `dash_enemy_ghost_end`

### `VaultTrigger` obstacle-side tuning
- `directionality`
- `traversal_model`
- `duration_override`
- `obstacle_height`
- `arc_clearance`
- `player_contact_buffer`
- `activation_overlap_tolerance`
- `landing_clearance_radius`
- `landing_clearance_center_height`
- `landing_ray_height`
- `landing_ray_depth`
- `side_margin`
- `strip_end_margin`

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
   - dodge end-state recovery
   - vault entry only near valid obstacles
   - vault landing remains on valid floor with clearance
   - crouch release only stands when the upper clearance volume is free
   - crouch blocks attack, dodge/dash, and vault starts
4. Keep normalized enemy-ghost windows within `[0, 1]` progress ranges.
5. Prefer tuning long-obstacle behavior on `traversal_model = STRIP_OFFSET` triggers before adding more authored segments.

## Notes
- Current tuning split is intentional:
  - shared player movement/mobility/vault feel lives in `player_controller.gd`
  - obstacle-specific vault setup lives on `VaultTrigger`
- This keeps authored obstacle tuning local while preserving one shared player runtime.
