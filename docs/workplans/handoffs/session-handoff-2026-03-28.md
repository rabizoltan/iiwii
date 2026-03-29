# Session Handover

## Active Scope
The shared player mobility foundation is now implemented and committed. The current active planning scope is player vault traversal as the next traversal slice, with mantle or climb-up intentionally separated into future planning and not active implementation work yet.

## Scope Boundaries
- Do not reopen melee-navigation refinement unless a concrete regression appears or a new explicit scope is chosen.
- Do not treat camera control as still active implementation work for the current milestone.
- Do not reopen the completed dodge or dash mobility foundation casually; build on it.
- Keep vault and mantle as separate traversal slices.
- Do not start vault code from the mantle notes; mantle or climb-up remains future planning only.

## Current Focus
- The repo now has a committed shared mobility runtime on `Shift` with tunable `dodge` and `dash` profiles.
- The next active traversal planning doc is vault, focused on contextual low-obstacle crossing with authored traversal affordances.
- Mantle or climb-up is documented separately as future planning, including likely low-mantle and high-mantle bands, but no mantle implementation is active yet.

## What Was Done
- Diagnosed and fixed the first-shot hitch by introducing a shared spawn warm-up path and later committing it as `53bc703`.
- Implemented the shared mobility foundation in `godot/scripts/player/player_controller.gd` with one tunable runtime for `dodge` and `dash`, including cooldown, travel lock, and temporary enemy-body ghosting.
- Fixed the `Shift` dodge binding in `godot/project.godot` so the action actually triggers.
- Fixed the mobility handoff so dash starts smoothly even while movement input is already held.
- Committed the mobility runtime and its doc sync in:
  - `8011fe0` `feat(mobility): add tunable dodge and dash foundation`
  - `c610a49` `docs(mobility): close slice and sync decisions`
- Discussed vault versus mantle and documented the boundary.
- Added active planning for vault and separate future planning for mantle or climb-up without writing traversal code for either today.

## Files Touched
Committed during this session:
- `godot/project.godot`
- `godot/scripts/player/player_controller.gd`
- `godot/scripts/main/demo_main_controller.gd`
- `godot/scripts/main/spawn_warmup_manager.gd`
- `godot/scripts/main/spawn_warmup_manager.gd.uid`
- `godot/scenes/main/DemoMain.tscn`
- `docs/architecture/code-map.md`
- `docs/decisions/ADR-005-traversal-and-verticality-model.md`
- `docs/decisions/ADR-007-input-and-controls.md`
- `docs/systems/movement-spec.md`
- `docs/technical/feature-matrix.md`
- `docs/technical/godot-conventions.md`
- `docs/technical/tuning-map.md`
- `docs/technical/validation-map.md`
- `docs/workplans/README.md`
- `docs/workplans/completed/player-mobility-foundation-slice.md`
- `docs/workplans/roadmaps/behavior-slice-roadmap.md`
- `docs/workplans/roadmaps/player-traversal-and-movement-slice-roadmap.md`

Currently modified or uncommitted planning docs:
- `docs/systems/movement-spec.md`
- `docs/systems/traversal-and-verticality.md`
- `docs/workplans/README.md`
- `docs/workplans/roadmaps/behavior-slice-roadmap.md`
- `docs/workplans/roadmaps/player-traversal-and-movement-slice-roadmap.md`
- `docs/workplans/active/player-vault-traversal-slice.md`
- `docs/workplans/planned/player-mantle-climb-up-slice.md`

## Decisions Made
- First traversal implementation should be one shared mobility runtime with tunable `dodge` and `dash` profiles, not two unrelated systems.
- Explicit runtime hitch prevention for spawned gameplay objects should be handled through a shared warm-up path rather than one-off actor hacks.
- Vault should mean crossing over a low authored obstacle and landing on the far side at roughly the same floor level.
- Mantle or climb-up should remain a separate future slice for getting onto meaningfully higher surfaces.
- Future mantle should likely distinguish at least two bands: low mantle and high mantle.
- Traversal affordances such as vault and mantle should be explicitly authored through dedicated environment-side nodes or components rather than pure geometry guessing.

## Open Problems
- The new vault and mantle planning docs are not committed yet.
- Vault has not been implemented yet; only planning and boundary decisions are documented.
- Mantle or climb-up remains future planning only.
- Runtime validation remains manual; there is still no automated gameplay regression coverage for movement or traversal.

## Next Recommended Step
1. Decide whether to commit the new vault and mantle planning docs as their own documentation commit.
2. When implementation resumes, start from `docs/workplans/active/player-vault-traversal-slice.md` and keep scope limited to low authored obstacle crossing.
3. Do not mix platform climb-up into the vault implementation; if vault stabilizes later, open mantle or climb-up as its own slice from `docs/workplans/planned/player-mantle-climb-up-slice.md`.

## Other Threads
- The camera slice remains complete and should not be reopened implicitly.
- The spawn warm-up infrastructure is now part of the runtime baseline for future first-use hitch prevention.
- The movement docs currently reflect the committed mobility baseline plus uncommitted future traversal planning updates.
