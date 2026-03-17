# High-Level Architecture
Category: Runtime Architecture
Role: Reference Contract
Last updated: 2026-03-18
Last validated: pending

## Purpose
- Define the runtime shape of the project at the highest level.
- Separate current singleplayer-first implementation reality from the later multiplayer target.

## Current Phase
- Runtime: one local Godot runtime.
- Simulation: local player input drives simulation directly.
- Persistence: local profile writeback after mission resolution.
- Focus: movement, combat feel, enemy navigation, and stable gameplay foundations.

## Multiplayer Target
- One Godot runtime per player.
- One player acts as authoritative session host.
- Steam services provide lobby discovery, peer connection, and session plumbing.
- Clients send intents; the host validates authoritative outcomes.

## Main Flows
### Mission Flow
- Current phase: local mission start and local simulation.
- Multiplayer target: host starts the mission and owns mission truth.

### Gameplay Flow
- Current phase: input, combat, and AI resolve locally.
- Multiplayer target: clients submit intents, host validates, host replicates authoritative state.

### Progression Flow
- Mission ends on extract or failure.
- Current phase: local runtime applies progression changes directly.
- Multiplayer target: each player applies local progression changes from authoritative mission results.

## Architectural Priorities
- Keep authority boundaries explicit.
- Isolate gameplay rules from UI and transport.
- Keep persistence player-owned.
- Avoid early structure that would block later multiplayer integration.

## Scaling Strategy
- Prefer systems that scale content and simulation through reuse rather than one-off manual work.
- For high-activity gameplay, prefer pooled or recycled runtime objects over constant spawn/free churn when profiling justifies it.
- Prefer shared update paths and explicit subsystem ownership before reaching for per-entity complexity or heavier architecture.
- Use procedural or data-driven authoring where it meaningfully reduces repeated asset work, but do not force it into areas where hand-authored content is clearer.
- Treat advanced data-oriented or multi-core architecture as a scale tool, not a default requirement; adopt it only when the real game volume justifies the extra complexity.
