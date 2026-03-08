# ADR-010: Session Flow — Host World, Own-Town Return

## Status
Accepted

## Context
iiWii is co-op PvE with:
- host-authoritative missions
- player-owned saves/progression
- drop-in/out friendly sessions

We need to define what happens “after the mission” and what “return to town” means for host and joiners.

## Decision
- While connected, the party plays in a **host-owned world instance**:
  - host chooses mission, difficulty/tier, and starts the run
  - host is authoritative for mission state and outcomes
- After mission end (extract success, wipe, or abort):
  - **each player returns to their own Town locally**
  - each player applies rewards/progression to **their own save**
  - the session/lobby can remain connected (optional), but Town state is local per player

## Implications
- “Town” is not a shared authoritative space by default.
- Joiners never become dependent on the host’s town progression.
- Mixed progression is expected; for simplicity, host sets mission tier for that session.

## Consequences
- Better drop-in/out experience
- Avoids “I can only progress when the host is online”
- Matches player-owned progression model
