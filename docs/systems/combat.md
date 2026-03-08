# Combat

## Purpose
- Define combat behavior for the current prototype and near-term vertical slice.
- Keep this doc focused on combat rules, not broader class or progression design.

## Core Rules
- Current phase: combat is resolved locally in the singleplayer-first slice.
- Multiplayer target: host authoritatively resolves hit validation and damage.
- Weapons have distinct cadence, range profile, and mastery hooks.
- Enemies pressure movement, positioning, and target priority.

## Current Prototype Scope
- Basic hitscan attack loop is implemented.
- Input: `primary_attack` (Mouse Left).
- Aim-pick ray (camera cursor ray) uses `AIM_PICK_MASK = 19`:
  - WorldSolid (1)
  - GroundAim (2)
  - Hurtbox (16)
- Shot ray starts from player chest and uses `HITSCAN_MASK = 17`:
  - WorldSolid (1)
  - Hurtbox (16)
- WorldSolid blocks shots before target hurtboxes.
- If the hit collider or its parent has `apply_damage(amount)`, damage is applied.
- Dummy target exists in the testbed with HP and destroy-on-death behavior.

## Aiming Rules
- Shots are driven by cursor pick point, then fired from player chest toward that point.
- A parallax-safe fallback is present:
  - if chest hitscan misses but cursor directly picked a valid damage target and no world-solid blocks chest-to-pick-point, damage still applies.

## Debugging
- Persistent shot debug lines are spawned per click:
  - red = hit
  - blue = miss
- Lines auto-expire after a short duration.

## Out Of Scope For This Doc
- Class role definitions
- Talent tree structure
- Town progression
- Inventory persistence

## Tuning Metrics
- Time-to-kill bands per enemy tier.
- Down/death rate by mission depth.
- Resource burn rate before and after extraction checkpoints.
