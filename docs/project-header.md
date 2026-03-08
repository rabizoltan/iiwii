# Project Header

## Project
- Name: `iiwii`
- Genre: co-op extraction action game
- Engine: Godot
- Primary language: GDScript
- Networking target: Steam P2P lobby, host-authoritative session model

## Delivery Phase
- Product target: co-op extraction action game.
- Current implementation phase: singleplayer-first vertical slice.
- Multiplayer is a planned later phase and current decisions should remain compatible with it.

## Core Product Statement
Players launch from a persistent town into dangerous missions, choose to extract safely or push deeper for better rewards, and return to improve long-term power through player-owned progression.

## Hard Constraints
- Co-op network model is host-authoritative; clients are never trusted for game-state authority.
- Account progression belongs to each player profile; no shared town save file.
- Hero death is permadeath by default; hero-bound progress is lost while town-bound progress persists.
- C++ GDExtension is optional and reserved for measured performance hotspots.

## Near-Term Scope
- Build a singleplayer-first vertical slice proving core loop quality and gameplay foundations.
- Keep architecture compatible with later Steam P2P host-authoritative multiplayer integration.
- Ship one town, a small mission set, core combat kit, extraction flow, and persistence.
- Keep architecture simple enough to iterate quickly with a small team.
