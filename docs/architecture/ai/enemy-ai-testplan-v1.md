# Enemy AI Navigation v1 — Test Plan

## Required test fixtures (scenes)
A) CornerWedge (repro case)
- L-shaped obstacle + a tight corner where nav path tends to hug the edge.
- Player placed behind/around obstacle.
- Spawn points that force enemies to turn around the corner.

B) NarrowCorridors
- Corridor just wide enough for Small, too narrow for Large.

C) LOSBlockers
- Thin pillars + thick walls.

D) CapabilityGates
- Vault link, crouch tunnel, jump link.
- Each link uses capability nav bits (4+).

---

## Tests

### 1) Target selection stability (no jitter)
Setup:
- 2 players at similar distance, then one moves closer.
Pass:
- Enemy does not rapidly switch targets back and forth.
- Switch occurs only when hysteresis threshold is exceeded.

### 2) Melee gather behavior
Setup:
- 30 melee vs 1 player in open area.
Pass:
- Enemies spread around player reasonably (not perfect surround required).
- They do not orbit to far-side points unnecessarily.
- They can engage when close enough (arrival tolerance).

### 3) Ranged donut + LOS peeking
Setup:
- 10 ranged vs player with walls/cover.
Pass:
- Ranged seeks a position in the distance band with LOS.
- If LOS lost, it repositions (peek) rather than shooting into a wall.

### 4) Ranged kiting (strafe)
Setup:
- Player pushes into ranged minimum distance.
Pass:
- Ranged retreats while strafing (tangent component), not pure backpedal-only.
- If strafe direction is blocked, it flips side or re-samples a goal.

### 5) Corner wedge stuck repro (must pass)
Setup:
- Use CornerWedge fixture.
- Spawn 10–20 enemies approaching corner simultaneously.
Pass:
- No enemy remains pinned > 3 seconds.
- Stuck recovery triggers and resolves jam.
- Recovery escalates if needed (detour/widen/anti-clump).

### 6) Mixed sizes + nav layer correctness
Setup:
- Spawn Small, Medium, Large together.
Pass:
- Each enemy uses only its size nav mesh.
- Large does not attempt paths through narrow corridors only Small can traverse.
- Clearance validation rejects goals that do not fit.

### 7) Unreachable target behavior
Setup:
- Player uses a traversal that an enemy lacks (capability not allowed).
Pass:
- Enemy keeps that player as target (does not drop due to unreachable).
- Enemy moves toward closest reachable anchor and continues attempting until threat changes.

### 8) Performance sanity
Setup:
- 100 enemies active in the same area.
Pass:
- No per-frame repaths.
- Staggered ticks prevent spikes.
- Debug counters show bounded repaths/goal changes.

---

## Debug overlay checklist (F3)
Per enemy:
- Path polyline
- Goal point marker
- LOS ray(s) and LOS bool
- Text: target_id, goal_age, stuck_time, recovery_step
- Counters: repath_count, stuck_count, goal_changes, target_switches