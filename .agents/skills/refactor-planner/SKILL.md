---
name: refactor-planner
description: "Use this when a refactor plan must be created, not implemented, for an existing codebase. Supports Quick and Deep modes: Quick = short narrow execution plan; Deep = primary and secondary findings, guardrails, stability conditions, detailed slices, and documentation/archive closure. Use it when the user wants a subsystem, file, folder, or architecture-coupling refactor organized into a structured task document."
---

The goal of this skill is to produce a structured, executable refactor plan.

Important: this skill plans refactors, it does not implement them.

## Modes

- `Quick`: narrow scope, shorter plan, fewer execution slices, fast handoff
- `Deep`: fuller plan with primary + secondary findings, stronger guardrails, and documentation / archival closure

Typical use:
- `$refactor-planner Quick GameBootstrap`
- `$refactor-planner Deep UI coupling`

## Workflow

1. Define the problem clearly.
2. Primary findings.
3. Secondary findings.
4. Refactor goal.
5. Guardrails.
6. Invariants / stability conditions when relevant.
7. Execution slices.
8. Task board (`Todo`, `In Progress`, `Done`).
9. Closure: docs update + feature matrix update + task archival.

## Location Rules

Default active task location:
- `docs/workplans/`

Closed task location:
- `docs/archive/`

If the repo uses a different convention, adjust script parameters consciously, but for this project the default workflow should remain `docs/workplans -> docs/archive`.

## Deterministic Helper Scripts

Use these scripts:
- `scripts/create_refactor_task.py`
- `scripts/update_task_status.py`
- `scripts/complete_refactor_task.py`

### 1. Create a task

```powershell
python .agents/skills/refactor-planner/scripts/create_refactor_task.py `
  --title "Refactor: Terrain Render Boundary" `
  --mode Deep `
  --goal "Reduce renderer ownership overload without changing feature behavior." `
  --primary-finding "God-object style TerrainMeshRenderer" `
  --primary-finding "Ad-hoc orchestration config writes" `
  --guardrail "Current feature set remains unchanged" `
  --guardrail "Behavior must not change" `
  --tasks-dir "docs/workplans"
```

### 2. Move task status

```powershell
python .agents/skills/refactor-planner/scripts/update_task_status.py `
  --task-file "docs/workplans/refactor-terrain-boundary.md" `
  --from "Todo" `
  --to "In Progress" `
  --item "Choose the first safe slice."
```

### 3. Close and archive a task

```powershell
python .agents/skills/refactor-planner/scripts/complete_refactor_task.py `
  --task-file "docs/workplans/refactor-terrain-boundary.md" `
  --archive-dir "docs/archive"
```

## Required Output Shape

- topic
- refactor goal
- primary findings
- secondary findings
- task file path
- short execution summary
- created helper script/template artifacts

## Behavioral Guardrails

- Do not plan a one-shot giant refactor.
- Do not mix cleanup with feature development.
- Do not produce implementation patches in this skill.
- If the scope is too broad or too vague, ask at most 3 focused questions.
