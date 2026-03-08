# Combat

## Purpose
- Define combat behavior for the vertical slice.
- Keep this doc focused on combat rules, not broader class or progression design.

## Core Rules
- Current phase: combat is resolved locally in the singleplayer-first slice.
- Multiplayer target: host authoritatively resolves hit validation and damage.
- Weapons have distinct cadence, range profile, and mastery hooks.
- Enemies pressure movement, positioning, and target priority.

## Early Vertical Slice Scope
- Start with a simple direct attack model.
- Attacks should respect line-of-sight blockers before applying damage.
- Damage application should target valid enemy hurt targets only.
- A simple target dummy is sufficient for early validation.

## Aiming Rules
- Shots are driven by cursor pick point, then fired from player chest toward that point.
- A parallax-safe fallback is recommended:
  - if chest hitscan misses but cursor directly picked a valid damage target and no world-solid blocks chest-to-pick-point, damage still applies.

## Debugging
- Persistent shot debug lines are useful per click:
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
