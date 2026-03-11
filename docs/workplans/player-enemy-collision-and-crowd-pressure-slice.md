# Player-Enemy Collision And Crowd Pressure Slice

## Status
- `planned`

## Purpose
- Replace the current baseline "player walks into enemies and pushes them" behavior with a clearer and cheaper collision model.
- Keep dense melee crowds readable without relying on continuous shove feedback loops.
- Define the next implementation slice before code changes begin.

## Design Decision
1. Normal player locomotion should not push enemies away.
2. Enemy pressure should come from spacing, body blocking, and attack cadence, not from continuous push-response physics.
3. Player escape should be handled by a short explicit `ghosted` or `unhindered` movement state on dodge or another escape move.
4. Enemy displacement should come from authored combat effects such as knockback, shove, launch, or scripted displacement.
5. Enemy crowds near the player should be managed by soft separation, lateral local steering, and a limited active melee front line.

## Target Player-Facing Behavior
1. Walking into enemies creates resistance or body pressure, but does not physically shove enemies out of the way.
2. The player can escape dense packs by using dodge or another dedicated escape action that temporarily passes through enemies.
3. Enemy attacks and positioning should still make crowding dangerous.
4. Player combat actions may still move enemies when that movement is an explicit combat effect.

## Target Enemy-Facing Behavior
1. Enemies outside melee range still use navigation and soft spreading to approach.
2. Near the player, enemies prefer local sideways adjustment over hard collision fighting.
3. Only a limited number of enemies should be active front-line pressurers in tight melee range.
4. Rear enemies should queue, orbit shallowly, or wait for pressure space instead of trying to force themselves through the front line with constant contact pushes.
5. Enemy-enemy crowding should tolerate some overlap or softness rather than devolving into rigid solver thrash.

## Scope
- Player normal movement collision against enemies.
- Player dodge or escape ghosting behavior.
- Enemy crowd pressure behavior near the player.
- Validation and profiling of dense pack scenarios after the baseline push mechanic is removed.

## Out Of Scope
- New attack abilities or full combat rework.
- Full crowd simulation.
- New enemy archetypes.
- Ranged enemy spacing rules.
- Replacing the current enemy approach and close-range state machine.

## Implementation Plan
1. Remove baseline player push from `player_controller.gd`.
2. Keep the enemy external movement influence path only for authored combat displacement.
3. Add a short `ghosted` or `unhindered` window to player dodge or another explicit escape move.
4. Add a simple cap for active melee front-line enemies near the player.
5. Retune close-range enemy crowd behavior after baseline push is gone.
6. Re-profile dense crowd scenes and compare against the current logs.

## Acceptance Criteria
1. Walking into enemies no longer applies baseline push to them.
2. Dense enemy packs remain readable and threatening without turning into constant physics wrestling.
3. Player dodge or escape reliably breaks out of enemy contact by passing through enemies for a short window.
4. Enemy packs no longer rely on player shove feedback to look alive near the player.
5. Enemy performance in the dense-pack push test improves relative to the current baseline.
6. Enemy knockback or shove still works when triggered by explicit combat effects.

## Validation Notes
1. Keep the current enemy and player profiling logs during the migration.
2. Compare before and after behavior specifically in the "player presses into dense enemy pack" scenario.
3. Evaluate both feel and cost:
   - enemy profile hot buckets
   - player crowd-push profile activity
   - readability of the front line
   - escape reliability during dodge

## Success Condition
- Crowd pressure becomes a deliberate gameplay rule instead of a side effect of baseline body-push physics.
