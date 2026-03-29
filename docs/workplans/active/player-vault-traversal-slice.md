# Player Vault Traversal Slice

## Status
- `active`

## Purpose
- Define the first contextual vault traversal slice without mixing it with mantle, climb-up, or broader parkour systems.
- Give the player a clean authored way to cross low obstacles such as benches, fallen trees, and low barricades.
- Preserve a clear architectural split between low obstacle crossing and meaningful elevation gain.

## Current Role
- This is the active planning document for the next traversal implementation slice.
- It captures the agreed vault definition and the authored-traversal approach before code begins.
- Runtime truth still belongs to [movement-spec.md](d:/Game/DEV/iiWii/iiwii/docs/systems/movement-spec.md) and [traversal-and-verticality.md](d:/Game/DEV/iiWii/iiwii/docs/systems/traversal-and-verticality.md).

## Design Decision
1. Vault is a short contextual traversal move over a low authored obstacle.
2. Vault returns the player to roughly the same floor level on the far side.
3. Vault is not mantle, climb-up, ledge grab, or free jump.
4. Getting onto a meaningfully higher platform belongs to a later mantle or climb-up slice.
5. Obstacle traversal should be explicitly authored through dedicated traversal nodes or components instead of pure geometry guessing.

## Vault Definition
Vault means:
- cross over a low obstacle
- start from one side and land on the far side in one committed motion
- remain near the same floor level
- use authored traversal data from the obstacle

Good v1 examples:
- fallen tree
- bench
- low barricade
- short fence segment
- sandbag line

Out of scope for vault v1:
- crate tops
- ledges
- rooftop lips
- higher platforms
- wall climb
- hang or shimmy behavior

## Why This Boundary
1. Low obstacle crossing and climb-up onto higher surfaces create different detection, collision, and level-design problems.
2. Mixing vault and mantle into one first slice would blur validation and broaden scope too much.
3. A dedicated low obstacle vault slice is easier to author, debug, and validate in combat spaces.

## Scope
- one contextual `Space` input path for vault
- authored obstacle traversal affordance for vaultable obstacles
- valid approach-side checks
- valid far-side landing checks
- short committed traversal motion across the obstacle
- lockout of normal locomotion, attacks, and mobility while vaulting
- temporary enemy-body ghosting during traversal if needed for readability and consistency
- demo-scene validation fixtures for 2-3 low obstacles

## Locked Decisions For V1
1. Vault requires `Space` plus active movement intent toward the obstacle.
2. Standing still next to a vaultable obstacle is not enough to start vault.
3. Vault detection should come from nearby authored vault nodes rather than raw geometry guessing.
4. Candidate selection should prefer valid authored vault nodes in front of the player, then choose the nearest valid candidate among them.
5. Vault nodes should support authored directionality:
   - default expectation is one-way setup
   - bidirectional use is allowed when explicitly authored for that obstacle
6. Attack should remain on left mouse button; `Space` should be reserved for vault in this slice.
7. Landing validation should prioritize world-valid landing space and same-floor intent rather than treating nearby enemies as a hard start blocker.
8. Enemy-body collision should be temporarily ghosted during the committed vault motion, then restored after vault ends with gentle separation if overlap remains.
9. Vault motion should use a fixed-duration committed move with a small readable arc rather than full animation-driven root motion.
10. Forward-facing tolerance should be forgiving rather than strict; a roughly `45` degree front cone is the intended starting point for v1.
11. Vault activation distance should stay close and readable rather than long-range; use a short forgiving band around the entry region and tune from a practical middle ground.
12. Arc height should derive from obstacle height with a small clearance margin rather than requiring per-obstacle manual arc authoring in v1.
13. A simple `VaultTrigger`-style authored node with entry and exit anchors is preferred for v1; a richer link model is not required for the first low-obstacle vault slice.

## Out Of Scope
- mantle or climb-up
- ledge grab or hang
- ladders or climbable walls
- free jump
- automatic geometry-derived parkour detection
- moving obstacle traversal
- AI use of vault links
- authored VFX/audio polish beyond minimal validation support

## Authored Traversal Pattern
Best-practice baseline for this project:
1. the environment should declare that an obstacle supports vault traversal
2. the traversal declaration should live on a dedicated node or component such as `VaultTrigger` or `TraversalMarker`
3. the player runtime should own execution of the vault
4. the obstacle-side traversal node should own obstacle-specific traversal data

The authored traversal node should define at least:
- traversal type, currently `vault`
- valid approach side or region
- start anchor or alignment expectation
- exit landing anchor
- optional duration or local tuning overrides

Recommended v1 authored-node shape:
- use a simple `VaultTrigger`-style setup
- store an entry region plus explicit exit landing anchor
- avoid introducing a more general traversal-link model unless a later slice truly needs it for ladders, ziplines, or other point-to-point connectors

Recommended v1 ownership split:
- obstacle-side vault node owns obstacle-specific setup:
  - entry region or approach side
  - exit landing anchor
  - optional duration override
  - whether the obstacle is one-way or bidirectional
- player runtime owns shared vault behavior:
  - candidate filtering and selection
  - lockouts and state transitions
  - committed motion and arc shaping
  - temporary enemy ghosting
  - end-of-vault collision recovery

This is preferred over raw geometry guessing because it is more reliable, more readable for level design, and easier to extend later to mantle, crouch-pass, or ladder traversal.

## Activation Rules
Vault should start only if:
1. the player presses `Space`
2. a valid authored vault traversal node is nearby
3. the player is approaching from an allowed side
4. the player has active movement intent toward the obstacle at the moment vault is requested
5. the far-side landing location is valid
6. the player is not already inside another lock state such as dodge or vault

Candidate selection for v1:
1. gather nearby authored vault nodes
2. discard nodes that are not on an allowed approach side
3. discard nodes that are not sufficiently in front of the player's current facing and movement intent
4. use a forgiving front-facing cone; roughly `45` degrees is the intended starting threshold for v1
5. choose the nearest remaining valid candidate

Landing validation for v1:
1. the landing anchor must fit the player against world geometry and major blockers
2. the landing should return the player to roughly the same floor level
3. nearby enemy bodies should not hard-block vault start by themselves

Activation distance for v1:
1. vault should start only from a short readable distance near the entry region
2. do not allow long-range vault activation because it will look fake
3. do not require exact last-moment collider touch because that makes timing feel too strict
4. start from a short forgiving middle-ground band and tune in playtests

## Runtime Expectations
- Vault should briefly take over motion and suppress normal locomotion.
- Vault should suppress attacks during the traversal.
- Vault should suppress dodge or dash during the traversal.
- Rotation should align to vault direction for the duration of the move.
- Vault should use a short fixed-duration committed move with a small readable arc.
- The readable arc should be derived from obstacle height with a small clearance margin and clamped to sane limits.
- Enemy bodies should be temporarily ghosted during the committed motion.
- If the player finishes inside enemy bodies, the runtime should resolve that overlap gently rather than canceling the traversal or turning vault into a knockback move.
- The player should land on the far side without becoming a climb-up system.

## Validation Targets
1. bench-style low obstacle vault
2. fallen-tree-style low obstacle vault
3. low barricade vault with clear far-side landing
4. invalid-side approach should not start vault
5. invalid landing should block vault start
6. attacks and dodge should stay locked during vault travel
7. normal locomotion should resume cleanly after vault ends
8. standing still and pressing `Space` should not start vault
9. when two vault nodes are nearby, the player should use the valid forward-facing candidate rather than an arbitrary nearest one
10. nearby enemies should not make an otherwise valid vault fail to start

## Acceptance Criteria
1. `Space` starts vault only in a valid authored vault situation.
2. The player crosses low obstacles cleanly and lands on the far side.
3. The player does not climb onto meaningfully higher platforms through the vault system.
4. Vault behavior is readable and deterministic in combat-adjacent spaces.
5. The authored traversal data lives on obstacle-side traversal nodes or components rather than being guessed entirely from mesh geometry.
6. The slice leaves a clean later path for a separate mantle or climb-up implementation.

## Follow-Up Candidates
- [player-mantle-climb-up-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/planned/player-mantle-climb-up-slice.md)
- crouch slice
- authored traversal VFX/audio support
- AI traversal affordance support
