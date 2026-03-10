# Documentation Index

This folder contains the active project documentation for `iiwii`.

## How To Read This
Use this order when you need fast context:

1. [project-header.md](d:/Game/DEV/iiWii/iiwii/docs/project-header.md)
2. [vision/game-vision.md](d:/Game/DEV/iiWii/iiwii/docs/vision/game-vision.md)
3. [vision/core-loop.md](d:/Game/DEV/iiWii/iiwii/docs/vision/core-loop.md)
4. [decisions/README.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/README.md), then the relevant ADRs in [`decisions/`](d:/Game/DEV/iiWii/iiwii/docs/decisions)
5. [architecture/README.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/README.md), then the relevant runtime docs in [`architecture/`](d:/Game/DEV/iiWii/iiwii/docs/architecture)
6. [systems/README.md](d:/Game/DEV/iiWii/iiwii/docs/systems/README.md), then the relevant gameplay rule docs in [`systems/`](d:/Game/DEV/iiWii/iiwii/docs/systems)
7. [technical/README.md](d:/Game/DEV/iiWii/iiwii/docs/technical/README.md), then the relevant implementation constraint docs in [`technical/`](d:/Game/DEV/iiWii/iiwii/docs/technical)
8. Optional task guidance in [`workplans/`](d:/Game/DEV/iiWii/iiwii/docs/workplans)

## Source Of Truth
- `decisions/`: accepted architectural decisions. If another doc conflicts, ADRs win.
- `architecture/`: runtime structure, data ownership, subsystem contracts.
- `systems/`: gameplay rules and player-facing mechanics.
- `vision/`: product intent and success criteria.
- `technical/`: implementation standards and conventions.
- `research/`: non-normative notes. Useful for direction, not final authority.
- `workplans/`: execution guidance and sequencing. Useful for delivery, not product truth.

## Repository Maintenance
- Track actual implementation state in [feature-matrix.md](d:/Game/DEV/iiWii/iiwii/docs/technical/feature-matrix.md).
- Track actual runtime file ownership and references in [code-map.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/code-map.md).
- Follow [development-governance.md](d:/Game/DEV/iiWii/iiwii/docs/technical/development-governance.md) for mandatory update rules when code starts landing.

## Terminology
- `player-owned progression`: progression stored per player profile; never shared as one party-wide town save.
- `hero-bound`: progression or gear attached to a specific hero and lost when that hero dies under default permadeath rules.
- `town-bound`: persistent progression that survives hero death and helps future heroes.
- `host-authoritative`: in multiplayer, the host owns mission truth and validates outcomes; clients send intent and render replicated state.

## Current Project Framing
- Product target: co-op extraction action game.
- Current implementation phase: singleplayer-first vertical slice.
- Foundation slice status: initial Godot 4.6 gameplay baseline is implemented and accepted as a prototype milestone.
- Current engineering focus: behavior-specific follow-up slices after the completed player attack and melee close-range enemy behavior work.
- The next planned behavior slice is combat feedback and debug behavior, but it remains blocked pending explicit scope decisions.
- Multiplayer remains a later phase and current decisions should stay compatible with it.

## Current Runtime Baseline
- A Godot 4.6 project now exists under `godot/`.
- The first runnable prototype baseline already includes:
  - player movement
  - basic enemy navmesh chase
  - minimal projectile attack
  - enemy HP and death
- That baseline should now be extended through behavior slices rather than more open-ended prototype polishing.

## Best Entry Points By Task
- Movement and traversal: [systems/movement-spec.md](d:/Game/DEV/iiWii/iiwii/docs/systems/movement-spec.md), [systems/traversal-and-verticality.md](d:/Game/DEV/iiWii/iiwii/docs/systems/traversal-and-verticality.md), [decisions/ADR-005-traversal-and-verticality-model.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-005-traversal-and-verticality-model.md), [decisions/ADR-007-input-and-controls.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-007-input-and-controls.md)
- Enemy navigation and combat positioning: [architecture/ai/enemy-ai-navigation-v1.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/ai/enemy-ai-navigation-v1.md), [architecture/ai/enemy-ai-config-v1.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/ai/enemy-ai-config-v1.md), [architecture/ai/enemy-ai-testplan-v1.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/ai/enemy-ai-testplan-v1.md), [decisions/ADR-017-navmesh-size-layers.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-017-navmesh-size-layers.md), [decisions/ADR-018-enemy-ai-nav-v1-approach.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-018-enemy-ai-nav-v1-approach.md)
- Combat: [systems/combat.md](d:/Game/DEV/iiWii/iiwii/docs/systems/combat.md), [systems/classes-and-abilities.md](d:/Game/DEV/iiWii/iiwii/docs/systems/classes-and-abilities.md), [systems/tuning-and-stats.md](d:/Game/DEV/iiWii/iiwii/docs/systems/tuning-and-stats.md)
- Current execution planning: [workplans/behavior-slice-roadmap.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/behavior-slice-roadmap.md), [workplans/player-attack-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/player-attack-behavior-slice.md), [workplans/enemy-close-range-behavior-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/enemy-close-range-behavior-slice.md)
- Implementation status and code ownership: [feature-matrix.md](d:/Game/DEV/iiWii/iiwii/docs/technical/feature-matrix.md), [code-map.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/code-map.md), [development-governance.md](d:/Game/DEV/iiWii/iiwii/docs/technical/development-governance.md)
- Progression and death rules: [architecture/save-and-progression.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/save-and-progression.md), [systems/player-hero-progression.md](d:/Game/DEV/iiWii/iiwii/docs/systems/player-hero-progression.md), [systems/progression-weapon-mastery.md](d:/Game/DEV/iiWii/iiwii/docs/systems/progression-weapon-mastery.md), [systems/death-and-extraction.md](d:/Game/DEV/iiWii/iiwii/docs/systems/death-and-extraction.md), [decisions/ADR-011-hero-death-safe-state-switching-and-party-continuity.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-011-hero-death-safe-state-switching-and-party-continuity.md), [decisions/ADR-013-progression-split-town-knowledge-vs-hero-build.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-013-progression-split-town-knowledge-vs-hero-build.md)
- Multiplayer target model: [architecture/networking.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/networking.md), [research/steam-multiplayer-notes.md](d:/Game/DEV/iiWii/iiwii/docs/research/steam-multiplayer-notes.md), [decisions/ADR-004-networking-model.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-004-networking-model.md), [decisions/ADR-008-multiplayer-replication-style.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-008-multiplayer-replication-style.md), [decisions/ADR-010-session-flow-host-world-own-town-return.md](d:/Game/DEV/iiWii/iiwii/docs/decisions/ADR-010-session-flow-host-world-own-town-return.md)

## What Is Intentionally Not Here
- Historical prototype prompts and noisy planning scraps were removed.
- LLM-operation documents were moved out of `docs/` into [`meta/`](d:/Game/DEV/iiWii/iiwii/meta) so they do not pollute product and engineering context.
