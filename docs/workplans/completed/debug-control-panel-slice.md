# Debug Control Panel Slice

## Status
- `completed`

## Current Role
- Historical delivery record for the shared debug control panel slice.
- Current runtime ownership and reusable validation entry points should now be read from [code-map.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/code-map.md) and [validation-map.md](d:/Game/DEV/iiWii/iiwii/docs/technical/validation-map.md).
- This document preserves the execution scope and delivery-time validation gates.

## Goal
Add a shared runtime debug control panel so behavior slices can be validated without hardcoded one-off debug toggles.

## Why This Is Separate
- Developer-facing debug tooling is a different concern from player-facing combat feedback.
- Enemy AI, projectile validation, and later combat slices all need the same centralized debug controls.

## Step Status Board
- Step 0 - Lock debug panel scope: `completed`
- Step 1 - Add global debug menu shell: `completed`
- Step 2 - Wire first toggle set: `completed`
- Step 3 - Validation pass: `completed`

## Baseline Rules
1. The debug menu opens and closes with `F3`.
2. The menu owns shared debug flags instead of per-feature hardcoded hotkeys.
3. Initial toggle set includes:
   - enemy navigation path
   - projectile debug line
   - lightweight runtime stats and enemy profiling visibility
4. Debug features are developer-facing and may stay visually simple.
5. The panel should help validate active behavior slices without redefining gameplay behavior.

## Execution Order

### Step 0 - Lock Debug Panel Scope
Status: `completed`

Actions:
1. Separate debug tooling from player-facing combat feedback.
2. Define the minimum first toggle set needed for current validation work.

Exit gate:
- The slice can proceed without mixing feedback and tooling requirements.

### Step 1 - Add Global Debug Menu Shell
Status: `completed`

Actions:
1. Add raw `F3` input handling for debug menu open/close.
2. Add a shared in-game panel in the demo scene.
3. Make the panel own shared debug flags.

Exit gate:
- A centralized runtime debug menu exists in-scene.

### Step 2 - Wire First Toggle Set
Status: `completed`

Actions:
1. Add enemy navigation path toggle support.
2. Add projectile debug line toggle support.
3. Add lightweight runtime stats and enemy profiling support.

Exit gate:
- The first debug features can be enabled and disabled from one panel.

### Step 3 - Validation Pass
Status: `completed`

Actions:
1. Verify `F3` opens and closes the panel reliably.
2. Verify enemy nav path lines react to the panel toggle.
3. Verify projectile debug lines appear only when enabled.
4. Verify runtime stats and enemy profiling only appear when the panel is active.

Current validation state:
- `F3` menu toggle works in the demo scene through main-scene global input handling.
- enemy nav path toggle has been manually checked and corrected for local-space rendering.
- projectile debug-line toggle has been manually validated in the demo scene.
- lightweight runtime stats and enemy profiling are available through the shared overlay rather than enemy-local debug labels.

Exit gate:
- The panel is usable for ongoing behavior slice validation in the demo scene.

## Success Criteria
1. Pressing `F3` opens and closes a debug menu.
2. The menu exposes shared debug controls for enemy nav path, projectile debug lines, runtime stats, and enemy profiling.
3. Enemy scripts consume shared debug state instead of hardcoded local-only display assumptions.
4. Projectile debug lines and nav-path rendering can be toggled without changing gameplay rules.

## Non-Goals
- final combat hit feedback
- final enemy HP presentation rule
- production UI styling
- persistence of debug preferences across launches

## Historical Next Slice Note
After this slice was validated, the intended follow-on was:
- [enemy-close-range-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/stale/enemy-close-range-behavior-slice.md)

For the current planning entry point, read [behavior-slice-roadmap.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/roadmaps/behavior-slice-roadmap.md).
