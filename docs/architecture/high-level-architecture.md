# High-Level Architecture
Category: Runtime Architecture
Role: Reference Contract
Last updated: 2026-03-16
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
