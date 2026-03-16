# Networking
Category: Multiplayer Architecture
Role: Reference Contract
Last updated: 2026-03-16
Last validated: pending

## Purpose
- Define the target multiplayer architecture.
- This doc is not the primary implementation guide for the current singleplayer-first milestone.

## Target Model
- Steam P2P lobby for discovery and invites.
- Host-authoritative co-op simulation.
- Clients are visualization and input peers, not rule authorities.

## Authority Rules
- Host validates combat hits, damage, loot generation, objective completion, extraction, and mission success/fail state.
- Clients submit input or action requests.
- Conflicting client state is corrected by host snapshots or events.

## Replication Strategy
- Reliable channel:
  - objective state
  - extraction results
  - inventory/progression-relevant commits
- Unreliable channel:
  - movement
  - aim
  - other transient updates where correction is acceptable
- Sequence IDs or timestamps are used for de-duplication and stale packet rejection.

## Failure Handling
- Disconnect during mission: player may rejoin if the session is still active.
- Host disconnect: mission ends in v1 and players return to their own town with failure-safe resolution.
- Anti-cheat posture in v1: trust-minimized authority boundaries, not a full anti-cheat stack.

## Current Scope Note
- Current implementation work should remain compatible with this model.
- Do not pull multiplayer complexity into singleplayer-first tasks unless the task explicitly requires it.
