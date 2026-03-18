# Player Traversal And Movement Slice Roadmap

## Status
- `planned`

## Current Role
- Parent planning document for future traversal slices.
- This roadmap is not an implementation spec by itself; each traversal feature should still get its own narrower slice before code starts.
- Current movement and collision truth should be read from [movement-spec.md](d:/Game/DEV/iiWii/iiwii/docs/systems/movement-spec.md), [code-map.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/code-map.md), and the crowd-pressure baseline at [player-enemy-collision-and-crowd-pressure-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/completed/player-enemy-collision-and-crowd-pressure-slice.md).

## Purpose
- Preserve the deferred player movement work as an explicit next-day planning artifact.
- Keep traversal work separate from combat and enemy crowd-pressure slices.
- Avoid reopening the crowd-pressure baseline just to add dodge, dash, vault, or crouch behavior ad hoc.

## Recommendation
Player movement should not be implemented as one large catch-all slice.

The better structure is:
1. one parent traversal roadmap
2. several smaller slices with clear success criteria

## Why Split It
1. Dodge or dash has direct combat and collision implications.
2. Vault has level-geometry, trigger, and collision implications.
3. Crouch has collision-shape, movement-speed, and animation implications.
4. Mixing them into one implementation pass would create unnecessary risk and blurry validation.

## Recommended Slice Breakdown

### Slice A - Player Dodge Or Dash Traversal
Status:
- `planned`

Suggested scope:
1. directional dodge or dash activation
2. duration, speed, and cooldown rules
3. temporary `ghosted` or `unhindered` enemy-body behavior
4. interaction with aiming and attack lockouts

Why first:
1. It is the most directly connected deferred item from the crowd-pressure slice.
2. It gives the player an explicit answer to dense enemy contact.

### Slice B - Player Vault Traversal
Status:
- `planned`

Suggested scope:
1. vault trigger requirements
2. obstacle validation
3. vault displacement and duration
4. demo-scene validation fixtures

Why second:
1. It depends more on scene setup and traversal geometry than on combat feel.

### Slice C - Player Crouch And Movement-State Rules
Status:
- `planned`

Suggested scope:
1. crouch enter and exit rules
2. crouch collision shape changes
3. crouch speed and movement handling
4. standing/crouching interaction with other traversal states

Why third:
1. It is lower urgency for the current combat and crowd-pressure baseline.

## Optional Later Follow-Up
- If the game later needs a dedicated sprint, slide, or traversal-tech slice, define it separately rather than folding it into the first three slices.

## Source Documents To Revisit
- [movement-spec.md](d:/Game/DEV/iiWii/iiwii/docs/systems/movement-spec.md)
- [player-enemy-collision-and-crowd-pressure-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/completed/player-enemy-collision-and-crowd-pressure-slice.md)
- [behavior-slice-roadmap.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/roadmaps/behavior-slice-roadmap.md)

## Suggested Restart Point
When work resumes, start by deciding whether Slice A should be:
1. a short dodge
2. a longer dash
3. or a single movement skill with tuning values that can later branch

That decision should be made before code changes begin.

After that decision, create or update a focused active slice doc before implementation.
