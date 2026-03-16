# Module Boundaries
Category: Runtime Architecture
Role: Reference Contract
Last updated: 2026-03-16
Last validated: pending

## Purpose
- Define responsibility boundaries between major runtime modules.
- Prevent cross-module leakage and hidden ownership.

## Core Modules
- `Bootstrap`: startup, environment checks, config wiring.
- `Gameplay`: mission state, combat, AI, objectives, extraction rules.
- `Progression`: player-owned profile state, validation, and writeback.
- `Net`: lobby/session lifecycle, transport, replication.
- `UI`: menus, HUD, feedback, summaries.
- `Data`: static configs and tuning tables.

## Dependency Rules
- `UI` reads state and sends intent; it does not own gameplay truth.
- `Gameplay` may emit progression outcomes but does not perform file I/O.
- `Progression` owns save/load and validation for profile updates.
- `Net` transports and replicates state; it does not define combat or progression rules.
- `Data` is read by runtime modules and should not depend on gameplay state.

## Ownership
- Mission truth:
  - Current phase: local `Gameplay`.
  - Multiplayer target: host `Gameplay`.
- Account truth: each player's local `Progression` module.
- Presentation truth: none. UI and VFX are consumers, not authorities.

## Current Scope Note
- `Net` is a target-layer concern for the current milestone, not the main implementation focus.
- `Gameplay`, `Progression`, and `Data` are the most relevant module boundaries right now.
