# Enemy Navigation And Movement Performance Optimization Slice

## Status
- `stale`

## Role
- Historical record of the earlier enemy navigation and movement performance restart attempt.
- Kept only for context and link preservation.

## Why It Is Stale
- The earlier restart plan no longer cleanly matches the current investigation and decision flow.
- New architectural decisions were made after deeper diagnosis, especially around:
- far-vs-near goal behavior
- goal-selection cost reduction strategy
- nav-refresh correctness before extra cadence complexity
- registry-scan reduction and close-range steering cleanup order

## Current Replacement
- Use [enemy-dense-scene-navigation-performance-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/active/enemy-dense-scene-navigation-performance-slice.md) as the active current execution guide.

## Historical Notes
- This older plan remains useful only as a reminder that broader attempts were rolled back and the current pass should stay narrow, measurable, and independently revertable.
