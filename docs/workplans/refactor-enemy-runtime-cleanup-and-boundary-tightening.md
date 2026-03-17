# Task: Refactor: Enemy Runtime Cleanup And Boundary Tightening

Last updated: 2026-03-17
Status: active
Mode: Deep

## Goal
Bring enemy runtime, navigation helpers, and debug surfaces into a small, explicit, maintainable architecture without changing current gameplay behavior.

## Primary Findings
- enemy_controller.gd still owns too much orchestration and transient state despite helper extraction
- docs and implementation drift remain around movement-state-machine ownership and current debug/runtime truth
- enemy debug/profiling code is cleaner after recent removals but still leaves dead seams, stale profiling buckets, and weak boundary lines

## Secondary Findings
- -

## Guardrails
- Current enemy movement behavior in DemoMain must remain unchanged
- Do not combine refactor slices with new combat or AI features
- Keep F3 menu-driven debug and profiling working throughout the refactor
- Each slice must end in a runnable intermediate state

## Invariants
- No runtime ordering regression.

## Execution Order
- Capture ownership map and scope boundaries.
- Execute primary refactor slices incrementally.
- Apply secondary cleanup only after primary stability.
- Finish with docs update, matrix sync, and archival.

## Todo
- [ ] Select first primary slice and mark In Progress.

## In Progress
- (none)

## Done
- (none)

## Completion & Documentation
- update related docs
- update feature matrix
- mark task as done
- move task from docs/workplans/ to docs/archive/
