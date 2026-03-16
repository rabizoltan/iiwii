---
name: llm-start
description: "Use this at the start of a development session when you need a fast project context reconstruction. Follow a priority order: handover, core docs, feature/system indexes, recent changes, entry points, then produce a short session context summary."
---

Use this skill at the start of a development session when you need fast, practical project context without scanning the whole repository blindly.

Typical use:
- `llm-start`

Primary goals:
- find the most important documents quickly
- identify the current work focus
- identify the most important entry points
- produce a short usable session context summary

Important limits:
- do not blindly scan the full repository
- use prioritized context reconstruction
- prefer structured documents over guessing
- if something cannot be detected, say so explicitly

Context reconstruction order:

## 1. Session handover
- Look for a handover document.
- Typical names include:
  - `HANDOVER.md`
  - `SESSION_HANDOVER.md`
  - `LLM_HANDOVER.md`
  - `docs/workplans/session-handoff-*.md`
  - `docs/session-handover.md`
- Do not rely only on exact filenames; also check similar handover-style names.
- If there are multiple candidates:
  - prefer the most recently modified one
  - prefer one under `docs/workplans/` or `docs/`
- If there is no handover:
  - continue without error
- If a handover exists, interpret it using this shared session structure:
  - `# Session Handover`
  - `## Active Scope`
  - `## Scope Boundaries`
  - `## Current Focus`
  - `## What Was Done`
  - `## Files Touched`
  - `## Decisions Made`
  - `## Open Problems`
  - `## Next Recommended Step`
  - `## Other Threads`
- Within those sections:
  - `Active Scope` is the primary scope reference
  - `Scope Boundaries` defines what is in and out
  - `Other Threads` are secondary, not equal to the main session goal

## 2. Core project documentation
- Find the main project docs.
- Do not depend on fixed filenames.
- In this repo, start from `docs/README.md` and then the relevant section indexes.
- Prefer documents that clearly describe:
  - architecture
  - systems
  - features
  - runtime behavior
  - gameplay or application mechanics
  - design overview
- `README` is high priority, but not the only source

## 3. Feature / system index documents
- If a feature matrix, architecture index, subsystem index, or system overview exists, use it for scope mapping.
- In this repo, typical starting points are:
  - `docs/technical/feature-matrix.md`
  - `docs/architecture/README.md`
  - `docs/architecture/code-map.md`
  - `docs/decisions/README.md`
- Use these to identify:
  - main subsystems
  - important modules
  - project terminology

## 4. Recently modified files
- If git is available:
  - inspect recent commits
  - inspect recently modified files
- Focus on:
  - which files were touched recently
  - which subsystem seems to be under active development
- Do not perform full blame or broad log analysis; a small relevant sample is enough

## 5. Entry points
- Identify likely entry points.
- Do not assume language or engine in advance.
- Typical patterns:
  - main runtime loop
  - main scene
  - startup script
  - bootstrap file
  - primary system entry
- Look for files that appear to initialize, launch, bootstrap, or drive the system

Working style:
- move top-down
- if the handover and main docs already give a clear picture, do not open unnecessary extra files
- inspect code-side entry points only as much as needed for the summary
- if a handover exists:
  - read `Active Scope` first
  - treat it as the primary session context
  - do not treat `Other Threads` as equal main scope

Git fallback:
- if git is unavailable, say so
- in that case the `Recent Changes` section may remain more uncertain

Review style:
- short
- practical
- avoid long audits
- do not invent unseen subsystems

Required output sections:
- `Session Context Summary`
- `Active Scope`
- `Scope Boundaries`
- `Project Overview`
- `Current Focus`
- `Recent Changes`
- `Important Systems`
- `Entry Points`
- `Suggested Next Context`

Output rules:
- keep the summary short and usable
- keep only the highest-signal information in each block
- if a block is uncertain or not detectable, say so briefly
- if a handover exists, do not blur the main task together with side threads
- `Active Scope` always takes priority over `What Was Done` or `Other Threads`

Token hygiene:
- start only with:
  - handover candidates
  - core doc candidates
  - system / feature index candidates
  - git recency
- do not go into repo-wide deep reading
- highlight only the most relevant 1-3 entry points

The final answer should be in English.
