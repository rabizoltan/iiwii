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
- Baseline fire mode is single-click single-shot.
- Baseline cooldown is `0.5` second.
- Baseline shots do not pierce.
- Baseline projectile range is unlimited for the slice.
- Baseline shooting should feel deliberate and aimed:
  - not blind bullet-hell spam
  - not extremely slow long-delay shooting

## Aiming Rules
- Shots are driven by cursor pick point, then fired from player chest toward that point.
- If the cursor is on ground, the projectile should resolve to that aimed ground point.
- If the cursor is on an enemy, the projectile should resolve to that enemy.
- If the cursor is on an obstacle, the projectile should resolve to that obstacle.
- Ground-targetable shots must remain possible for elevated shots and for targeting the ground between enemies.
- The player cannot aim at self.
- If there is no valid enemy, ground, or obstacle target under the cursor, the player does not shoot.
- A parallax-safe fallback is recommended:
  - if chest hitscan misses but cursor directly picked a valid damage target and no world-solid blocks chest-to-pick-point, damage still applies.

## Extension Rule
- Non-piercing shots are the default baseline.
- Piercing shots may be introduced later as a controlled extension through powers, talents, or similar progression hooks.
- Projectile speed is a tuning value and is not yet a locked design constant for this slice.

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
