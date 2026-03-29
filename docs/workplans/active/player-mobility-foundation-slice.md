# Player Mobility Foundation Slice

## Status
- `active`

## Purpose
- Establish a shared player mobility foundation for short dodge and longer dash behavior.
- Keep the first traversal implementation narrow, tunable, and reusable by future class kits.
- Provide the explicit escape movement deferred by the crowd-pressure baseline without mixing in full traversal scope.

## Current Role
- This is the active execution guide for the first traversal implementation slice.
- It translates the traversal roadmap into a buildable foundation without introducing class-aware behavior yet.
- Runtime movement truth still belongs to [movement-spec.md](d:/Game/DEV/iiWii/iiwii/docs/systems/movement-spec.md), [traversal-and-verticality.md](d:/Game/DEV/iiWii/iiwii/docs/systems/traversal-and-verticality.md), and [ADR-007-input-and-controls.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-007-input-and-controls.md).

## Design Decision
1. Build one shared mobility action foundation, not two unrelated mechanics.
2. Support two initial tunable profiles on that foundation:
   - `dodge`: shorter displacement, shorter commitment, smaller escape move
   - `dash`: longer displacement, stronger travel commitment, larger escape move
3. Keep the foundation displacement-based only in this slice; no blink or teleport behavior.
4. Keep class awareness out of this slice; future warrior/hunter/wizard differences should plug into the same shared foundation later.
5. Leave authored effect content such as trail VFX, end bursts, or hazard interactions for follow-up slices, but keep clean hooks for them.

## Why This Shape
1. The traversal roadmap already recommends deciding between short dodge, long dash, or one tunable movement skill before code begins.
2. A shared foundation reduces duplicated state, input, collision, cooldown, and lockout logic.
3. Future class kits and powerups can specialize profile values and effect hooks without forcing a rewrite of the runtime state machine.

## Scope
- One shared mobility activation path bound to the existing traversal input intent.
- Direction selection rules for mobility activation.
- Shared runtime state for travel lock, elapsed progress, and cooldown.
- Tunable profile surface for dodge vs dash distance, duration, cooldown, and ghosted/unhindered timing.
- Enemy-body escape behavior during the mobility window.
- Mobility/attack interaction rules for the current prototype.
- Demo-scene validation for both a short dodge profile and a longer dash profile.

## Out Of Scope
- Blink or teleport behavior.
- Vault implementation.
- Crouch implementation.
- Full class-aware runtime branching.
- Stamina, charges, talents, or upgrade trees.
- Final VFX/audio content for trail or end effects.
- Hazard-tag interactions beyond preserving a clean hook surface for later work.

## Shared Foundation Requirements
1. Mobility should use one common runtime state rather than separate hardcoded dodge and dash state machines.
2. Profile selection should be data/tuning driven for the current slice.
3. Activation should resolve direction from:
   - current movement direction
   - otherwise last movement direction
   - otherwise forward fallback
4. During mobility travel, regular locomotion and attacks should remain locked out unless a later explicit rule changes that.
5. Enemy-body escape behavior should be driven by the mobility state, not by restoring baseline shove behavior.
6. The foundation should expose clear start/travel/end hook points for later effects and powerups.

## Player-Facing Target Behavior
1. The player has one explicit escape movement action on `Shift`.
2. The same action can be tuned into either a short dodge or a longer dash.
3. Dense melee contact can be escaped through the mobility action instead of locomotion-driven push.
4. Dodge should feel like a slight evasive reposition.
5. Dash should feel like a more committed burst of movement in a direction.

## Implementation Guardrails
1. Do not add blink/teleport semantics in this slice.
2. Do not mix vault or crouch rules into the mobility foundation implementation.
3. Do not reopen baseline player shove logic.
4. Do not hardcode class-specific warrior/hunter/wizard branches yet.
5. Keep the tuning surface small and explicit.
6. Keep debug support lightweight; use existing `F3` tooling where possible rather than creating a parallel debug system.

## Proposed Runtime Shape
1. Add one mobility profile concept owned by the player movement runtime.
2. Keep the current `player_controller.gd` as the likely first implementation owner unless scope growth forces extraction.
3. Treat profile values as the current authoritative tuning surface for:
   - travel distance or speed
   - duration
   - cooldown
   - ghosted/unhindered start and end
   - optional attack lock timing if needed
4. If the implementation remains stable, later class kits should select or modify profiles rather than replacing the mobility runtime path.

## Execution Slices
1. Add the shared mobility state and tuning surface.
2. Implement activation, direction resolution, and movement lock behavior.
3. Add temporary enemy-body ghosted or unhindered behavior during mobility travel.
4. Validate one short dodge profile and one longer dash profile in `DemoMain.tscn`.
5. Update runtime docs, feature matrix, tuning map, and validation map after code lands.

## Acceptance Criteria
1. Pressing `Shift` triggers the new mobility action when not blocked by cooldown or lock state.
2. The mobility action can be tuned into both a short dodge and a longer dash without changing the core runtime path.
3. The player can escape dense enemy body pressure through the mobility action.
4. Normal locomotion still does not push enemies as a baseline behavior.
5. Regular attacks remain cleanly blocked or resumed according to the explicit mobility lock rules.
6. Demo-scene validation confirms both profile extremes feel distinct and stable.
7. The implementation leaves a clean follow-up path for future class-specific specialization and authored effects.

## Validation Notes
1. Reuse `DemoMain.tscn` as the first validation surface.
2. Validate at least:
   - short dodge profile against dense enemy contact
   - longer dash profile against dense enemy contact
   - cooldown enforcement
   - attack lockout during travel
   - return to normal locomotion after travel ends
3. Confirm no first-use hitch appears if mobility effects or spawned helpers are added later; register those through the shared spawn warm-up path.

## Success Condition
- The repo gains one stable, tunable mobility foundation that solves immediate escape movement needs and can later branch into class-specific dodge or dash flavors without a system rewrite.

## Follow-Up Candidates
- class-aware mobility profile selection
- authored end effects or travel trails
- vault slice
- crouch slice
- blink or teleport slice as a separate later design decision
