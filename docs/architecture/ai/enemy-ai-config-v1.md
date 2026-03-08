# Enemy AI Config v1

This config centralizes tunables so behavior changes don’t require rewrites.

## Global tunables
- THREAT_TICK_SEC: 0.35
- THREAT_SWITCH_MULT: 1.35
- GOAL_SELECT_TICK_SEC: 0.85
- GOAL_COMMIT_TIME_SEC: 0.75
- PATH_REPATH_MIN_SEC: 0.60
- EPS: 0.25

## Nav layers (size)
Scene already provides 3 nav regions and layers:
- SIZE_SMALL  = nav layer bit 1
- SIZE_MEDIUM = nav layer bit 2
- SIZE_LARGE  = nav layer bit 3
Source geometry group for baking: "Navigation"

Rule: each enemy must use exactly ONE size bit.

## Nav layers (capabilities)
Reserve nav bits >= 4 for links only:
- CAP_VAULT  = bit 4
- CAP_CROUCH = bit 5
- CAP_JUMP   = bit 6
(Example; adjust to your game)

Rule:
- NavigationRegions use only size bits (1..3).
- NavigationLink3D nodes use capability bits (4+).
- Enemy NavigationAgent uses: (one size bit) + (allowed capability bits).

## Melee ring
- MELEE_RING_CANDIDATES: 12
- MELEE_RING_SCALE: 1.15
- MELEE_RING_MIN: 1.2
- MELEE_RING_MAX: 3.0
- MELEE_ARRIVAL_TOLERANCE: 1.25

## Ranged donut + kite (strafe)
- RANGED_CANDIDATES: 16
- RANGED_MIN_DIST: 6.0
- RANGED_MAX_DIST: 10.0
- RANGED_ARRIVAL_TOLERANCE: 1.5
- KITE_MIN_DIST: 5.5
- KITE_STRAFE_WEIGHT: 0.60
  - 0.0 = pure retreat
  - 1.0 = pure strafe
- KITE_SIDE_FLIP_SEC: 2.0 (optional: swap strafe side periodically or when blocked)

## Candidate validation / wall-stuck prevention
- PROJ_MAX_DIST: 1.0
- CLEARANCE_MARGIN: 0.15
- WALL_CLOSE_PENALTY_MULT: 5.0

## Candidate scoring weights (path dominates)
- W_PATH: 1.0
- W_OCC: 0.4
- W_LOS: 0.8
- W_WALL: 1.2
- W_TURN: 0.2

## Soft occupancy
- OCC_RADIUS_MULT: 2.2     (relative to enemy capsule radius)
- OCC_MAX_SOFT: 4

## Stuck detector
- STUCK_SAMPLE_DT: 0.15
- STUCK_MIN_SPEED: 0.25
- STUCK_MIN_DIST: 0.8
- STUCK_MIN_PROGRESS: 0.03
- STUCK_TIME_THRESHOLD: 0.9
- STUCK_RECOVERY_COOLDOWN: 0.6

## Recovery ladder
- RECOVERY_EXCLUDE_LAST_K: 3
- RECOVERY_DETOUR_DIST: 1.5
- RECOVERY_WIDEN_FACTOR: 1.35
- RECOVERY_MAX_STEP: 4

---

## Per-enemy required fields
These must be defined per enemy type/variant:

### Size & nav
- size_class: Small | Medium | Large (explicit, preferred)
- nav_size_layer_bit: derived from size_class (1..3)
- capability_bits: bitmask (0 if none)

### Collision / clearance
- capsule_radius
- capsule_height
- avoidance_radius (default: capsule_radius * 1.15)

### Combat role
- is_ranged: bool
- melee_attack_range OR ranged_band_min/max
- projectile_los_requires: bool (default true)

### Movement tuning
- max_speed
- accel
- turn_speed
- separation_strength (if you have an extra local push)