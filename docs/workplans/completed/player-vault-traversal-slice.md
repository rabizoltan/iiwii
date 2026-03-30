# Player Vault Traversal Slice

## Status
- `completed`

## Purpose
- Deliver contextual low-obstacle vault traversal as a dedicated slice.
- Keep vault explicitly separate from mantle or climb-up.
- Ship an authored traversal model that level setup can tune without geometry guessing.

## Final Role
- This file is the completed implementation record for the vault slice.
- Runtime truth now lives in [movement-spec.md](d:/Game/DEV/iiWii/iiwii/docs/systems/movement-spec.md), [traversal-and-verticality.md](d:/Game/DEV/iiWii/iiwii/docs/systems/traversal-and-verticality.md), [code-map.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/code-map.md), and the runtime files under `godot/scripts/player/` + `godot/scripts/traversal/`.
- Mantle or climb-up remains a separate future slice at [player-mantle-climb-up-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/planned/player-mantle-climb-up-slice.md).

## Delivered Outcome
1. `Space` now triggers vault through the `vault` input action, while attack remains on left mouse button.
2. Vault start requires active movement intent plus a valid authored `VaultTrigger` candidate.
3. The player runtime gathers nearby registered triggers, filters invalid candidates, and chooses the best valid option by score.
4. Obstacle-side authored data now lives on `VaultTrigger` plus explicit anchor markers:
   - `EntryFaceAnchor`
   - `ExitFaceAnchor`
   - `EntryLandingAnchor`
   - `ExitLandingAnchor`
5. Directionality is authored per trigger with `ENTRY_TO_EXIT`, `EXIT_TO_ENTRY`, or `BIDIRECTIONAL`.
6. Two traversal models now exist per trigger:
   - `FIXED_ENDPOINT` for simple short obstacles
   - `STRIP_OFFSET` for long straight obstacles, preserving along-obstacle offset
7. Landing validity enforces floor hit, same-floor tolerance, and collision clearance.
8. Vault travel is a short committed code-driven move with a readable arc over the obstacle.
9. Enemy bodies are ghosted during vault travel and softly resolved if overlap remains at the end.
10. Demo validation fixtures and a reusable authored long-table setup were added for manual playtesting.

## Runtime Behavior Summary
- Current runtime owner: `godot/scripts/player/player_controller.gd`
- Trigger owner: `godot/scripts/traversal/vault_trigger.gd`
- Start gate:
  - player must be on floor
  - player must press `Space`
  - player must have active movement intent
  - movement intent must align with the candidate within the configured forward cone
  - landing must resolve to valid floor and clearance
- Current default player tuning:
  - `vault_duration = 0.6`
  - `vault_activation_distance = 1.2`
  - `vault_facing_angle_degrees = 65`
  - `vault_arc_min_height = 0.2`
  - `vault_arc_max_height = 2.5`
  - `vault_same_floor_tolerance = 0.6`
- Current motion model:
  - direct authored position interpolation from start to landing position
  - code-driven arc using `obstacle_height + arc_clearance`, clamped by the player exports above
  - regular locomotion, attack, and mobility remain locked during vault
- Current collision policy:
  - vault does not use `move_and_slide()` during traversal motion
  - enemy-body collision is ghosted during vault travel
  - world-valid landing is still required before vault starts
  - any enemy overlap at the end resolves gently instead of becoming a shove attack

## Authoring Model
### Shared `VaultTrigger`
`VaultTrigger.tscn` supplies the reusable `Area3D` trigger volume and script exports.

Each trigger owns obstacle-specific rules such as:
- directionality
- traversal model
- duration override
- obstacle height
- arc clearance
- contact/overlap tolerances
- landing clearance and ray settings
- strip end margin
- the four anchor paths

### Anchor Meaning
- `EntryFaceAnchor`: one start-side edge of the obstacle
- `ExitFaceAnchor`: the opposite start-side edge
- `EntryLandingAnchor`: landing reference on the `Entry` side
- `ExitLandingAnchor`: landing reference on the `Exit` side

### Trigger Meaning
- The blue trigger box is only the activation region.
- The trigger box does not define the landing by itself.
- The anchors define where crossing starts from each side and where landing should resolve.

### Long Obstacles
- Long straight obstacles should prefer `STRIP_OFFSET`.
- `STRIP_OFFSET` keeps the player aligned with where they started along the obstacle instead of funneling them toward one fixed middle landing point.
- Very irregular or curved obstacles may still want multiple authored segments later, but the long straight table setup now works as one strip-authored obstacle.

## Scope That Was Intentionally Kept Out
- Mantle or climb-up.
- Ledge grab, hang, ladders, and free jump.
- Animation-driven root-motion traversal system.
- AI traversal use of vault affordances.
- Full traversal VFX/audio pass.

## Acceptance Outcome
1. `Space` starts vault only in a valid authored vault situation. `completed`
2. Vault crosses low authored obstacles and lands on the far side. `completed`
3. Vault does not become climb-up or mantle behavior. `completed`
4. Enemy bodies do not hard-block committed vault travel. `completed`
5. Runtime keeps mantle as a separate future scope. `completed`
6. Slice leaves a clear follow-up path for crouch and mantle. `completed`

## Validation Notes
- Validation is still manual in editor/runtime playtests.
- Main validation surfaces:
  - `godot/scenes/main/DemoMain.tscn`
  - `godot/scenes/traversal/VaultFixture.tscn`
  - `godot/scenes/MyAssets/table.tscn`
- Core checks covered during implementation:
  - valid side starts
  - invalid side rejection
  - blocked-landing rejection
  - movement-intent requirement
  - lock behavior against other traversal/mobility states
  - long-obstacle strip-offset behavior
  - authored trigger/anchor tuning on reusable obstacles
- I did not run automated gameplay tests from the terminal; this repo still uses manual gameplay validation.

## Follow-Up Candidates
- crouch slice
- mantle/climb-up slice
- traversal VFX/audio polish
- AI traversal affordance usage
