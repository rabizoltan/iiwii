# Enemy AI Navigation v1

## Summary
Implement a robust enemy navigation + combat positioning system for up to ~100 enemies.
Enemies pick the highest-threat player (v1: distance-only) and move toward a goal point near that player:
- Melee: ring gather (close enough to engage)
- Ranged: donut positioning + LOS-based peeking + strafing kite (no backpedal-only)

The system must avoid common "corner wedge" stuck cases with explicit stuck detection + recovery.

---

## Goals
1) Target the player with the highest threat (v1: distance-only; supports future threat sources like damage/abilities).
2) Melee enemies gather around the target and attempt to hit (no perfect surround required).
3) Ranged enemies maintain a preferred distance band and kite via strafing while keeping LOS.
4) Enemies stay separated (no overlap). They can push slightly but should not permanently block each other.
5) Extreme robustness around obstacles/corners (must recover from wall-edge sticking).
6) Scale to ~100 active enemies without jitter (stagger updates; avoid per-frame repaths).

## Non-goals (v1)
- No advanced squad tactics or formations.
- No runtime navmesh cutting/carving.
- No expensive multi-agent global optimization.

---

## Key Constraints / Assumptions
- Host-authoritative simulation.
- Baked navigation exists with **3 size layers** already authored in the scene:
  - NavRegion_Small  (nav layer bit 1)
  - NavRegion_Medium (nav layer bit 2)
  - NavRegion_Large  (nav layer bit 3)
- All navigation meshes bake from the same world geometry using source group name: **"Navigation"**.
- Enemy sizes vary (capsule radius/height differs).
- Player may traverse areas enemies cannot; traversal is controlled via nav layers and links (capability bits).

---

## Architecture Overview

### Subsystems (modules)
A) Threat + Target Selection
B) Goal Selection (melee ring / ranged donut + kite)
C) LOS (line of sight) + Attack Gating
D) Locomotion (path following + avoidance/separation)
E) Stuck Detection + Recovery Ladder
F) Tick Scheduling (stagger timers to avoid spikes/jitter)

### High-level enemy loop
Each enemy runs a simple state machine:
- AcquireTarget (threat)
- ChooseGoal (goal selection: ring/donut)
- MoveToGoal (path follow + avoidance)
- Engage (attack if LOS + range; for ranged: kite/peek)
- StuckRecovery (if stuck triggers)

---

## A) Threat + Target Selection

### Threat table
Per enemy, maintain a table keyed by player_id:
- threat_value
- last_update_time

### v1 threat formula (distance-only)
Compute on THREAT_TICK_SEC (staggered per enemy):
- d = distance(enemy, player)
- threat = 1 / (d*d + eps)

### Target hysteresis (anti-jitter)
Keep current target unless:
- new_threat >= THREAT_SWITCH_MULT * current_threat

### Unreachable target behavior
Do NOT drop a target simply because unreachable.
Instead, compute an **anchor** on reachable nav space and continue pursuing (see Goal Selection).

---

## B) Goal Selection

### Key idea
Enemies do NOT path to the player position.
They path to a nearby **goal point** chosen from candidates around the player (or around an anchor if player unreachable).

Selection MUST prefer the **closest reachable** candidate by **path length** (not random angle).

### Shared definitions
- P = target player position
- E = enemy position
- A = anchor position (navmesh-projected P for enemy's nav layers)
- Center = P if reachable, else A
- Candidate C = point around Center (ring/donut sample)
- C_proj = candidate projected to navmesh (must exist)
- Clearance check uses the enemy capsule (radius/height) + margin

### Anchor point (for unreachable targets)
If the player is not on nav space reachable by this enemy:
- A = closest reachable nav point to P on the enemy's allowed nav layers
- All candidate generation centers on A (not raw P)

### Candidate generation

#### Melee (Ring gather)
- Generate MELEE_RING_CANDIDATES points around Center on radius r_melee
- r_melee = clamp(attack_range * MELEE_RING_SCALE, MELEE_RING_MIN, MELEE_RING_MAX)

#### Ranged (Donut positioning)
- Generate RANGED_CANDIDATES points inside band [RANGED_MIN_DIST, RANGED_MAX_DIST]
- Sampling can be:
  - multiple rings OR
  - random polar samples with minimum angular spacing

### Candidate validation (critical)
Candidate is valid only if:
1) C_proj exists and projection distance <= PROJ_MAX_DIST
2) Clearance check passes for this enemy size:
   - Do a shape query placing the enemy capsule at C_proj to ensure it does not intersect static world geometry
3) Optional but recommended:
   - Path exists to C_proj (NavigationAgent can compute path; invalid if empty)

### Candidate scoring (closest reachable wins)
Pick the candidate with the lowest score:

score(C) =
  W_PATH * path_length(E -> C_proj)
+ W_OCC  * occupancy_penalty(C_proj)
+ W_LOS  * los_penalty(C_proj -> P)
+ W_WALL * wall_proximity_penalty(C_proj)
+ W_TURN * turn_cost_penalty(E, C_proj)

Rules:
- Path length MUST dominate so enemies don’t choose far-side points.
- Occupancy is soft: crowded points still allowed.
- LOS is soft for movement: lack of LOS can be allowed, but affects scoring.
- Wall proximity penalty should strongly avoid “barely clears” candidates near corners.

### Soft slot occupancy
Maintain an occupancy metric around the target:
- Use a lightweight spatial check (distance-based) to count how many enemies target a similar goal area
- Occupancy penalty grows with count, but does not make candidate invalid

### Commitment window (no nervous retargeting)
Once a goal is selected, keep it for GOAL_COMMIT_TIME_SEC unless:
- target changed (hysteresis switch)
- stuck triggers
- ranged enters kite/peek state due to distance/LOS change
- Center shifts significantly (player moved far enough)

---

## C) LOS + Attack Gating

### LOS raycast
Default:
- From enemy chest/eye point to player chest point

Optional:
- A second ray to player head
- LOS is true if either ray is unobstructed

### Rules
- Attacks require LOS (hard gate) to prevent hitting through walls.
- Movement prefers LOS (soft scoring) but does not require it.

---

## D) Locomotion + Separation

### Path following
- Use NavigationAgent3D path following to the goal point
- Do NOT repath every frame
- Repath only when:
  - goal changed
  - enough time elapsed since last repath
  - agent deviated heavily from the path

### Separation
- Use avoidance where possible (agent radius slightly larger than capsule radius)
- Keep physical collision so enemies can push slightly
- Avoid relying purely on physics pushing for crowd movement (causes corner jams)

### Variable sizes
- Candidate clearance queries MUST use the real capsule size for each enemy.
- Avoidance radius should scale with capsule radius.

---

## E) Stuck Detection + Recovery (mandatory)

### Stuck detection (progress-based)
Sample every STUCK_SAMPLE_DT:
- dist_prev = distance(prev_pos, goal)
- dist_now  = distance(curr_pos, goal)
- progress = dist_prev - dist_now

Accumulate stuck_time when ALL hold:
- speed < STUCK_MIN_SPEED
- distance_to_goal > STUCK_MIN_DIST
- progress < STUCK_MIN_PROGRESS

Trigger STUCK_EVENT when:
- stuck_time >= STUCK_TIME_THRESHOLD

### Recovery ladder (must change behavior)
On stuck event, escalate steps with cooldown:

1) Re-pick goal (exclude last K candidates)
2) Local detour:
   - pick a nearby nav point offset sideways (1–2m), go there, then re-pick goal
3) Loosen constraints temporarily:
   - melee: widen ring radius band
   - ranged: widen donut band
4) Anti-clump override:
   - temporarily increase avoidance radius or reduce crowding pressure
   - prefer lower occupancy candidates aggressively

Never “repath to the exact same goal” as the only reaction.

---

## F) Tick scheduling (anti-jitter + perf)
Stagger across enemies using per-enemy randomized offsets:
- Threat tick ~0.35s
- Goal select tick ~0.85s
- Path repath minimum interval ~0.6s
- Stuck sampling ~0.15s

---

## Debug requirements (F3)
When debug overlay enabled:
- Draw current path (polyline)
- Draw current goal point + candidate ring/donut (optional)
- Draw LOS ray(s) + show LOS bool
- Per enemy text:
  - target_player_id
  - goal_age
  - stuck_time
  - recovery_step
  - repath_count
  - goal_changes
  - target_switches