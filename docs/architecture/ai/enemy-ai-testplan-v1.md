# Enemy AI Navigation v1 - Test Plan
Category: Verification
Role: Verification Guide
Last updated: 2026-03-16
Last validated: pending

## Status
- Mixed state.
- The broader v1 fixture set below is still a design target.
- The current repository does already contain a manual validation scene in [DemoMain.tscn](d:/Game/DEV/iiWii/iiwii/godot/scenes/main/DemoMain.tscn) that covers the shipped melee close-range slice: one-enemy hold behavior, multi-enemy soft spreading, player-moves-away follow behavior, and dense-crowd pressure testing.

## Required test fixtures
### A) CornerWedge
- L-shaped obstacle with a tight corner where nav paths tend to hug the edge
- player placed behind or around the obstacle
- spawn points that force enemies to turn around the corner

### B) NarrowCorridors
- corridor wide enough for `Small`
- corridor too narrow for `Large`

### C) LOSBlockers
- thin pillars
- thick walls

### D) CapabilityGates
- vault link
- crouch tunnel
- jump link
- each link uses capability nav bits 4 and above

## Tests

### 1. Target selection stability
Setup:
- 2 players at similar distance, then one moves closer

Pass:
- enemy does not rapidly switch targets back and forth
- switch occurs only when hysteresis threshold is exceeded

### 2. Melee gather behavior
Setup:
- 30 melee enemies vs 1 player in an open area

Pass:
- enemies spread around the player reasonably
- they do not orbit to far-side points unnecessarily
- they engage when close enough

### 3. Ranged donut and LOS peeking
Setup:
- 10 ranged enemies vs player with walls and cover

Pass:
- ranged seeks positions in the preferred distance band with LOS
- if LOS is lost, it repositions instead of shooting into a wall

### 4. Ranged kiting
Setup:
- player pushes inside ranged minimum distance

Pass:
- ranged retreats while strafing, not only backpedaling
- if the strafe direction is blocked, it flips side or re-samples a goal

### 5. Corner wedge stuck repro
Setup:
- use `CornerWedge`
- spawn 10 to 20 enemies approaching the corner simultaneously

Pass:
- no enemy remains pinned for more than 3 seconds
- stuck recovery triggers and resolves the jam
- recovery escalates when needed

### 6. Mixed sizes and nav layer correctness
Setup:
- spawn `Small`, `Medium`, and `Large` together

Pass:
- each enemy uses only its size nav mesh
- `Large` does not attempt paths through corridors intended only for `Small`
- clearance validation rejects goals that do not fit

### 7. Unreachable target behavior
Setup:
- player uses a traversal route an enemy lacks capability to follow

Pass:
- enemy keeps that player as target
- enemy moves toward the closest reachable anchor and continues trying until threat changes

### 8. Performance sanity
Setup:
- 100 active enemies in the same area

Pass:
- no per-frame repaths
- staggered ticks prevent spikes
- debug counters show bounded repaths and goal changes

## Debug Overlay Checklist
Per enemy:
- path polyline
- goal point marker
- LOS ray and LOS bool
- text fields:
  - `target_id`
  - `goal_age`
  - `stuck_time`
  - `recovery_step`
- counters:
  - `repath_count`
  - `stuck_count`
  - `goal_changes`
  - `target_switches`
