# ADR-011: Hero Death, Safe-State Switching, and Party Continuity

## Status
Accepted

## Context
iiWii has:
- permadeath heroes
- player-owned progression and saves
- co-op missions run as host-authoritative sessions
- own-town return after mission end

We need clear rules for what happens when a hero dies during a mission, whether the player stays connected, and when a player can select a different hero.

Plain language:
- **Safe state** = a moment where switching heroes cannot break the mission (e.g., Town/Lobby between missions).

## Decision
### 1) Death is final for that hero
- When a hero dies, that hero's `status` becomes `dead`.
- A dead hero cannot be selected again.
- Gear carried by that hero is lost (hero-bound gear loss).

Default rule:
- Permadeath is ON.

Optional future rule:
- A non-permadeath mode may be offered later.
- If enabled, it changes hero death handling only and does not change town-bound persistence.

### 2) The player stays connected
- The player remains connected to the host session after death (no forced disconnect).
- The player transitions to a **spectator/death state** until the mission ends, unless a future system explicitly allows respawn.

### 3) Hero switching is allowed only in safe states
Players may select a different hero from their own town **only** in safe states:
- Town / Lobby (between missions)
- mission end transition (extract success / wipe / abort), once returned to Town locally
- (Optional future) explicit respawn checkpoints/shrines, if introduced by a new ADR

Hero switching is **not allowed**:
- mid-mission during active gameplay
- as an immediate replacement to continue fighting after death (no "instant swap")

### 4) Mission continuity
- The mission continues for surviving players.
- Mission end is decided by host-authoritative rules (extraction, objectives, wipe conditions).

### 5) Save writeback
- On mission end, each player writes results to their own save:
  - death increments, hero marked dead, hero gear lost
  - extracted rewards apply to town resources and persistent unlocks as applicable

## Implications
- UI flow needs:
  - in-mission death/spectator screen
  - hero selection screen in Town/Lobby
- Networking needs:
  - player "alive/dead/spectating" state replication
  - host validation of death and mission end

## Consequences
- Death remains meaningful (permadeath + gear loss).
- Co-op remains smooth (players stay connected and can spectate).
- Prevents cheese/exploits from swapping heroes mid-mission.
- Leaves room for future respawn mechanics without rewriting core rules.
