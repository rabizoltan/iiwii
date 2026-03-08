# First Playable Vertical Slice - Execution Plan

## Goal
Create the first runnable gameplay slice that proves the core runtime foundation:
- player movement
- simple attack
- enemy chase
- navmesh obstacle routing
- enemy death

## Status
- `active`

## Step Status Board
- [ ] Step 0 - Governance setup
- [ ] Step 1 - Project bootstrap
- [ ] Step 2 - Player movement
- [ ] Step 3 - Enemy navigation foundation
- [ ] Step 4 - Basic combat loop
- [ ] Step 5 - Stability and debug pass

## Why This Is First
- It proves the basic game is actually programmable, runnable, and testable.
- It validates the current documentation focus:
  - movement
  - combat feel
  - enemy navigation
- It avoids premature work on progression, town systems, inventory, multiplayer, or content scale.

## Success Criteria
The first slice is successful when all of the following are true:
1. The Godot project opens and runs.
2. One playable scene exists.
3. Player can move reliably in a 3D top-down or slight-isometric scene.
4. Player can use a simple attack.
5. At least 2 enemies can chase the player using navmesh.
6. Enemies route around blocking obstacles, including a U-shaped obstacle.
7. Enemies can take damage and die.

## Scope Rules
- Keep the slice intentionally tiny.
- Use the smallest implementation that proves the behavior.
- Do not add progression, save/load, town, inventory, boss logic, or multiplayer.
- Do not build generalized architecture beyond what this slice actually needs.

## Execution Order

### Step 0 - Governance Setup
Status: `not_started`

Actions:
1. Keep [feature-matrix.md](d:/Game/DEV/iiWii/iiwii/docs/technical/feature-matrix.md) as the single source for actual implementation status.
2. Keep [code-map.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/code-map.md) as the single source for runtime file ownership and important references.
3. Follow [development-governance.md](d:/Game/DEV/iiWii/iiwii/docs/technical/development-governance.md) for every code change.
4. Do not start code without deciding where the first scene, player actor, enemy actor, and shared config entries will be tracked in the code map.

Exit gate:
- The project has explicit rules for feature status, file ownership, and doc updates before code starts landing.

### Step 1 - Project Bootstrap
Status: `not_started`

Actions:
1. Create the Godot project.
2. Create one main demo scene.
3. Add floor, a few obstacles, and one U-shaped obstacle.
4. Add a stable top-down or slight-isometric camera.
5. Define input actions needed for the slice.

Exit gate:
- Project launches into a visible playable scene.

### Step 2 - Player Movement
Status: `not_started`

Actions:
1. Add player actor root.
2. Implement XZ-plane movement.
3. Add collision with world obstacles.
4. Add simple facing behavior.
5. Add a small set of movement tuning values.

Exit gate:
- Player movement feels stable and predictable around obstacles.

### Step 3 - Enemy Navigation Foundation
Status: `not_started`

Actions:
1. Add one enemy actor.
2. Add navmesh world setup.
3. Add `NavigationAgent3D`-based chase behavior.
4. Validate routing around walls and the U-shaped obstacle.
5. Spawn at least 2 enemies in the scene.

Exit gate:
- Enemies reach the player by navigating around obstacles instead of pushing into them.

### Step 4 - Basic Combat Loop
Status: `not_started`

Actions:
1. Add the simplest viable player attack.
2. Add enemy HP.
3. Add enemy death.
4. Add attack cooldown or cadence.
5. Verify enemies can still navigate during combat.

Exit gate:
- Player can kill enemies in the playable test scene.

### Step 5 - Stability And Debug Pass
Status: `not_started`

Actions:
1. Tune player movement and attack feel.
2. Tune enemy chase and stop distance.
3. Add minimal debug support for:
   - enemy target/chase visibility
   - HP/death visibility
   - nav or stuck issues if needed
4. Confirm there are no obvious close-range collision or routing failures.

Exit gate:
- The slice is stable enough to serve as the foundation for the next gameplay feature.

## Explicit Non-Goals
- no save system
- no progression
- no town
- no inventory
- no multiplayer
- no bosses
- no procedural generation
- no large abstraction framework

## Deliverables
- Godot project bootstrap
- one main playable scene
- one player actor
- one enemy actor type
- simple attack
- navmesh obstacle test scene with U-shape
- basic debug visibility if needed

## Next Step After This Plan
After this slice is complete, the next likely work item should be one of:
1. traversal feature foundation
2. enemy combat behavior improvement
3. movement/combat tuning cleanup
4. early code structure cleanup based on what actually exists
