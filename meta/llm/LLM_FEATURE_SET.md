# Feature Set Overview (LLM-Oriented) — iiWii

## Purpose
Defines:
- What features exist
- Their maturity
- Their architectural impact
- Where to look in code

Keep concise. Link to key paths/files only.

---

# Feature Classification (required per feature)

- Status: (Prototype / VerticalSlice / Stable / Experimental / Deprecated)
- Layer: (Gameplay / Net / Save / UI / Data / Tools)
- Risk Level: (Low / Medium / High)
- Net Impact: (Yes / No)
- Save Impact: (Yes / No)
- Perf Sensitivity: (Low / Medium / High)
- Key Paths: (a few only)

---

# 1) Mission Flow (Director + Objectives)
Status: Prototype
Layer: Gameplay
Risk: High
Net Impact: Yes
Save Impact: Yes
Perf: Medium
Key Paths:
- godot/scripts/gameplay/
- docs/systems/missions-objectives.md

---

# 2) Combat Core
Status: Prototype
Layer: Gameplay
Risk: High
Net Impact: Yes
Save Impact: No
Perf: High
Key Paths:
- godot/scripts/gameplay/
- docs/systems/combat.md

---

# 3) Weapon Mastery Unlocks (Persistent)
Status: Prototype
Layer: Save + Gameplay
Risk: High
Net Impact: Yes
Save Impact: Yes
Perf: Low
Key Paths:
- docs/systems/progression-weapon-mastery.md
- docs/architecture/save-and-progression.md

---

# 4) Talents/Perks (Per-Hero)
Status: Prototype
Layer: Gameplay
Risk: Medium
Net Impact: Yes
Save Impact: Yes
Perf: Low
Key Paths:
- docs/systems/talents-perks.md

---

# 5) Town Meta Progression
Status: Prototype
Layer: Save + UI
Risk: Medium
Net Impact: No
Save Impact: Yes
Perf: Low
Key Paths:
- docs/systems/town-meta-progression.md

---

# 6) Steam Lobby + P2P Session
Status: Prototype
Layer: Net
Risk: High
Net Impact: Yes
Save Impact: No
Perf: Medium
Key Paths:
- godot/scripts/net/
- docs/architecture/networking.md

---

# Lifecycle Rules
When adding/removing/modifying a feature significantly:
1) Update this file.
2) Update LLM_ARCHITECTURE_INDEX.md if responsibilities changed.
3) Keep each feature summary <= ~10 lines.