# Tuning And Stats

This document lists where gameplay numbers are currently defined and how to tune them safely.

## Player Movement Tuning

### Resource Asset
- `res://resources/tuning/PlayerTuning_Default.tres`

### Resource Script
- `res://scripts/data/player_tuning.gd`

### Consuming Runtime Script
- `res://scripts/gameplay/player_controller.gd`

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

## Player Combat/Health Constants (Current)
- File: `res://scripts/gameplay/player_controller.gd`
- Fields currently still in script:
  - `ATTACK_DAMAGE`
  - `ATTACK_RANGE`
  - `MELEE_DAMAGE`
  - `MELEE_COOLDOWN`
  - `MELEE_FORWARD_OFFSET`
  - `MAX_HP`
  - ray masks/ray length values for targeting

If you need broader tuning unification, move these to a dedicated combat resource next.

## Enemy Stats And Behavior Tuning

### Base Enemy Type
- Scene: `res://scenes/gameplay/enemies/EnemyBasic.tscn`
- Script: `res://scripts/gameplay/enemies/enemy_basic.gd`

### Current Exported Enemy Stats
- `move_speed`
- `aggro_range`
- `stop_range`
- `attack_windup`
- `attack_cooldown`
- `attack_damage`
- `max_hp`
- `stagger_on_hit`

## How To Create A New Enemy Type
1. Duplicate `EnemyBasic.tscn` into a new scene file.
2. Keep script inheritance to `enemy_basic.gd` unless behavior fork is required.
3. Tune exported values in the duplicated scene:
   - speed, aggro range, stop range
   - attack windup/cooldown/damage
   - HP and stagger response
4. Place the new scene in testbed/spawner references.
5. Verify nav and combat behavior in `Testbed_CombatNav`.

## Safe Tuning Workflow
1. Change one variable cluster at a time (speed, then dodge, then vault).
2. Run from bootstrap (`F5`) and test focused behavior in CombatNav.
3. Validate no lock-state regressions:
   - crouch release recovery
   - dodge end-state recovery
   - vault entry only near valid obstacles
4. Keep i-frame window within `[0, 1]` normalized dodge progress.

## Notes
- Current tuning is hybrid:
  - movement in resource
  - combat and enemy values largely script/scene exports
- This is intentional for incremental migration without large refactors.
