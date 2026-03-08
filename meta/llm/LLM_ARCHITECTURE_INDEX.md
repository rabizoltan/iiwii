# Architecture Index (LLM-Optimized) — iiWii

## Purpose
Token-efficient architectural map of the project.
Not a full explanation document.

Rules:
- Keep concise.
- Prefer links/paths over narrative.
- Update when responsibilities move.
- Avoid duplicating code logic.

---

# 1) Gameplay Core (Authoritative Rules)
Purpose:
- Mission flow, combat rules, skills, enemy logic, progression rules.

Contains (examples):
- MissionDirector / MissionFlow
- Combat resolution (damage, status effects)
- Skill system (cooldowns, targeting)
- Enemy spawning/director (horde pressure)

Constraints:
- If multiplayer: host is authoritative for game-critical outcomes.
- RNG ownership must be explicit (host-owned for rolls that matter).
- No UI ownership of gameplay truth.

Entry Points:
- Mission start/end orchestration
- Combat resolution functions
- Progression awarding at extraction/end

Paths (expected):
- godot/scripts/gameplay/
- godot/scenes/gameplay/

---

# 2) Networking (Steam P2P, Host Authority)
Purpose:
- Lobby/session setup, transport integration, replication rules.

Contains:
- Lobby create/join/leave
- Host selection & session ownership
- RPC/message definitions
- Replication of player state / entities (as needed)

Constraints:
- Host-authoritative validation for damage/loot/progression changes.
- Clients send inputs/intent; receive state.
- Avoid desync by making authority explicit per system.

Paths (expected):
- godot/scripts/net/
- godot/addons/ (Steam plugin)
- docs/architecture/networking.md

---

# 3) Save & Progression (Player-Owned)
Purpose:
- Local saves for player-owned progression (town + unlocks + heroes).

Contains:
- Save schema + versioning
- Load/apply progression at boot
- Writing results after mission/extraction

Constraints:
- Each player owns their own save (no shared town save).
- Save format changes require migration/versioning notes.

Paths (expected):
- godot/scripts/core/ (save utilities)
- docs/architecture/save-and-progression.md

---

# 4) Presentation (Scenes/UI/VFX)
Purpose:
- Visuals, HUD, menus, feedback, audio.
- Must not contain authoritative game rules.

Contains:
- UI scenes and controllers
- FX, animation triggers
- Local-only cosmetics

Constraints:
- UI does not mutate core truth directly.
- Presentation reads state and sends intent to gameplay layer.

Paths (expected):
- godot/scenes/ui/
- godot/scripts/ui/
- godot/assets/

---

# 5) Data / Config
Purpose:
- Balance, item definitions, skill configs, enemy stats.

Constraints:
- Prefer data-driven configs to reduce code churn.
- Keep “tuning” separated from “rules”.

Paths (expected):
- godot/data/configs/
- godot/data/balance/

---

# 6) Optional Performance Layer (Future: GDExtension)
Purpose:
- Only introduced after profiling proves hotspots.

Candidates:
- Pathfinding
- Large-scale AI queries
- Heavy simulation loops

Constraints:
- C++ must not become the default.
- Keep stable interfaces between GDScript and extension modules.

Paths:
- cpp/