# Session Handoff - 2026-03-08

## What Was Done
- Reorganized the documentation structure for better AI and human navigation.
- Removed historical and noisy project documents that were no longer active sources of truth.
- Moved AI-assistant support documents out of `docs/` into `meta/llm/`.
- Renamed the Steam multiplayer research note to a stable, readable filename.
- Added top-level index documents for:
  - `docs/`
  - `docs/architecture/`
  - `docs/systems/`
  - `docs/technical/`
  - `docs/workplans/`
  - `meta/`
  - `meta/llm/`

## Documentation Structure Changes
- `docs/` now contains only active project documentation.
- `meta/` now contains assistant-facing and workflow-facing support material.
- `docs/workplans/` now clearly holds execution guidance rather than product truth.

## Architecture Pass
- Rewrote the active architecture docs to reduce overlap and make their roles explicit:
  - `high-level-architecture.md`
  - `module-boundaries.md`
  - `networking.md`
  - `save-and-progression.md`
- Clarified current phase vs target-state multiplayer architecture.
- Kept multiplayer as a later target while preserving compatibility in present decisions.

## Systems Pass
- Rewrote and narrowed system docs so each one answers a smaller, clearer question.
- Added `docs/systems/README.md` as the gameplay-rule entry point.
- Reduced overlap between:
  - combat
  - classes and abilities
  - hero progression
  - weapon mastery
  - town progression
  - death/extraction
  - inventory
  - missions/objectives

## Technical Pass
- Rewrote the active technical docs to separate workflow, conventions, standards, and release handling.
- Added `docs/technical/README.md` as the implementation-constraint entry point.

## Current Source-Of-Truth Layout
- `docs/decisions/`: highest authority for accepted architectural decisions
- `docs/architecture/`: runtime structure and ownership
- `docs/systems/`: gameplay rules
- `docs/vision/`: product intent
- `docs/technical/`: implementation constraints
- `docs/research/`: non-normative notes
- `docs/workplans/`: execution planning only
- `meta/`: non-project AI support material

## Current Project Framing
- Product target: co-op extraction action game.
- Current implementation phase: singleplayer-first vertical slice.
- Current engineering focus:
  - hero movement
  - enemy movement
  - combat feel
  - AI navigation foundations

## Suggested Next Steps
1. Add an ADR index so an AI can find the relevant decision file in one hop.
2. Review whether some older ADRs can be grouped by topic in the index:
   - platform/runtime
   - traversal/input/world model
   - progression/save/death
   - multiplayer/networking
   - AI/navigation
3. Re-check `research/` and `workplans/` periodically so they do not drift back into source-of-truth territory.
