---
name: llm-scope-guard
description: "Use this when you need to check whether the current development work has drifted away from the original task. Reconstruct the original scope, compare it to the current direction, flag drift, and suggest the smallest correct next step."
---

Use this skill when there is a risk of scope drift during a development session and you need to verify that the work still aligns with the original goal.

Typical use:
- `llm-scope-guard`
- `llm-scope-guard Original task: stabilize the save/load skeleton.`

Primary goals:
- reconstruct the original task scope
- determine the current work direction
- compare the two
- flag drift if the work has shifted
- provide the smallest correct recovery step

Important rules:
- do not suggest new features
- do not broaden the task
- this skill is for realignment, not ideation

Scope reconstruction order:

## 1. User prompt
- Treat the latest task-defining user instruction as the primary source.
- If the user clearly stated a goal, use it as the primary scope.

## 2. Session handover
- If a handover document exists, use it.
- Pay special attention to:
  - `Active Scope`
  - `Scope Boundaries`
  - `Current Focus`
  - `Next Recommended Step`
  - `Open Problems`
- Among those:
  - `Active Scope` is the authoritative scope reference
  - `Scope Boundaries` defines what is in and out
  - `Other Threads` are secondary, not the main task

## 3. Project documentation
- Consult main project docs only if needed to understand scope context.
- Typical sources:
  - `README`
  - architecture docs
  - feature matrix
  - system index
  - design docs
- Use these only for context interpretation, not scope expansion

Current work detection:
- Determine the current work direction from:
  - recently modified files
  - the current conversation
  - the code being inspected
  - the subsystem currently being edited or discussed

Drift analysis:
- Compare:
  - `Original Scope`
  - `Current Work`
- If a handover exists, reconstruct `Original Scope` with:
  - `Active Scope` taking priority
  - `Scope Boundaries` narrowing interpretation
  - `Other Threads` treated as secondary only

Classification:

### No Drift
- The current work directly serves the original goal.

### Mild Drift
- There are some related improvements or additions, but they are not strictly necessary.

### Strong Drift
- The work has moved into new features or subsystems that are not required for the original task.

Behavior rules:
- avoid inventing new features
- avoid widening scope
- prefer the smallest useful correction
- finish the original goal first, then consider follow-up improvements

If you notice a useful but non-essential improvement:
- place it under `Potential Future Work`
- do not put it under `Next Correct Step`

Guardrails:
- explicitly warn when:
  - the task expanded significantly
  - a new subsystem appears unnecessarily
  - unrequested refactors appear
- example warning:
  - `Detected scope drift: new subsystem proposal unrelated to original task.`

Token hygiene:
- start with user prompt + handover + recent changes
- use project documentation only as supporting context
- do not drift into a repo-wide audit

Output format:
- `Scope Analysis`
- `Original Goal`
- `Active Scope Reference`
- `Scope Boundaries`
- `Current Work`
- `Drift Assessment`
- `Out-of-Scope Elements`
- `Recommended Correction`
- `Next Correct Step`
- `Potential Future Work`

Output rules:
- include `Potential Future Work` only if it is real and useful
- `Next Correct Step` should always be the smallest helpful scope-faithful step
- keep the final answer short, practical, and willing to say no
- if a handover exists, state clearly that `Active Scope` was the primary reference

The final answer should be in English.
