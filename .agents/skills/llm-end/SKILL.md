---
name: llm-end
description: "Use this at the end of a development session when the project handover document needs a safe update. Summarize the end-of-session state, touched files, decisions, open problems, and next step, and prefer updating an existing handover file."
---

Use this skill at the end of a development session when you need to leave a clean handover for the next session.

Typical use:
- `llm-end`

Primary goals:
- update the existing handover document
- record what happened in the session
- record which files were touched
- record important decisions
- highlight open or unfinished points
- provide the next recommended step

Critical rules:
- always prefer updating an existing handover
- only create a new handover if none exists
- do not create multiple parallel handover files
- every handover should follow the same shared structure

Handover file discovery:
- Look for an existing handover document.
- Typical names include:
  - `HANDOVER.md`
  - `SESSION_HANDOVER.md`
  - `LLM_HANDOVER.md`
  - `docs/workplans/session-handoff-*.md`
  - `docs/session-handover.md`
- Do not rely only on exact filenames; check similar handover-style names too.
- If multiple exist:
  - prefer the most recently modified one
  - prefer one under `docs/workplans/` or `docs/`
- If none exist:
  - create a new one at:
    - `docs/workplans/session-handoff-<date>.md`

Session analysis:

## 1. Recent file changes
- If git is available:
  - inspect modified files in the working tree
  - inspect recent commits
  - inspect changes most related to the session
- Focus on:
  - which files were touched
  - which subsystem was under active work

## 2. Current project focus
- Determine the primary focus of the session.
- Sources:
  - modified files
  - commit messages
  - conversation context
- If uncertain, say so briefly

## 3. Decisions made
- Highlight important technical or documentation decisions made during the session.
- Typical examples:
  - architecture changes
  - refactor direction
  - new system or skill introduction
  - retirement of old logic

## 4. Unfinished work
- Collect open points.
- Typical examples:
  - TODO items
  - partially complete features
  - unresolved problems
  - next implementation step

Update strategy:
- do not blindly rewrite the whole document
- find the existing sections
- update them
- replace outdated information where needed
- keep earlier relevant context where useful
- do not duplicate lists or wording

Required sections:
- `Session Handover`
- `Active Scope`
- `Scope Boundaries`
- `Current Focus`
- `What Was Done`
- `Files Touched`
- `Decisions Made`
- `Open Problems`
- `Next Recommended Step`

Optional section:
- `Other Threads`

If a required section is missing:
- create it

Section update rules:
- `Active Scope`
  - this is the primary authoritative session goal
  - update it if the main session task changed
  - otherwise avoid rewriting it unnecessarily
- `Scope Boundaries`
  - keep it current and explicit
  - do not rename the section
- `Files Touched`
  - refresh the relevant list
- `Next Recommended Step`
  - replace it with the latest current next step
- `What Was Done`
  - keep it as a short end-of-session summary
- `Open Problems`
  - keep only truly open issues there
- `Other Threads`
  - use this for small side work or minor detours
  - do not elevate them to main-scope status
  - create or update it only if such side work actually happened

Shared handover format rule:
- Do not rename the sections above.
- Do not invent an alternative handover structure.
- `llm-start`, `llm-end`, and `llm-scope-guard` should all read or write the same handover format.

Guardrails:
- prefer update over rewrite
- do not create multiple handover files
- do not duplicate content
- preserve useful historical context
- do not remove important sections without replacement

Reasoning rules:
- keep reasoning minimal
- preferred effort:
  - `low`
  - `medium`
- never use `high`

Token hygiene:
- do not read the whole repository unnecessarily
- rely on:
  - handover candidates
  - git changes
  - session context
  - only the minimum necessary docs or files

Required output:
- which handover file was updated or created
- which sections changed
- a short practical confirmation

Output format:
- `Handover document updated: <file>`
- `Updated sections:`
- a short list of updated sections

The final answer should be in English.
