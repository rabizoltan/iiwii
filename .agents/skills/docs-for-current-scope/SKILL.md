---
name: docs-for-current-scope
description: Ensures that the current development scope is properly documented. Updates existing documentation when possible, creates new documentation when necessary, and updates the feature matrix so the feature becomes part of the project's documented structure.
---

Use this skill when the current development scope must be documented and you want to make sure the feature or subsystem remains discoverable later through the documentation layer and the feature matrix.

Typical use:
- `docs-for-current-scope`

Primary goals:
- determine the current feature or subsystem scope
- find existing documentation
- update an existing doc where possible
- create a new doc only when necessary
- update the feature matrix so the feature remains discoverable

Workflow:
1. identify the current scope
2. search for existing documentation
3. if a suitable doc exists, update it
4. if not, create a new doc
5. update the feature matrix or subsystem index

Scope detection:
- Determine current scope from these sources in order:
  1. session handover `Active Scope`
  2. user prompt
  3. recent work context
  4. feature review output
- If scope is not clear enough:
  - ask at most 3 short clarification questions

Documentation search:
- Always search existing docs before creating a new one.
- Typical locations:
  - `docs/architecture/`
  - `docs/systems/`
  - `docs/technical/`
  - `docs/workplans/`
  - `docs/decisions/`
- Typical doc types:
  - subsystem docs
  - architecture docs
  - feature docs
  - system design docs
- Always prefer updating an existing doc.

Updating existing documentation:
- If a suitable doc exists:
  - update it
  - add missing explanation where needed
  - clarify the feature goal
  - add related systems
- Do not duplicate already existing content.

Creating new documentation:
- Create a new doc only if:
  - no suitable existing document exists
  - and the feature is a distinct subsystem or distinct feature
- A new doc should typically cover:
  - `Feature Overview`
  - `Purpose`
  - `Responsibilities`
  - `Interactions with other systems`
  - `Constraints or assumptions`

Feature matrix update:
- Explicitly look for a feature matrix or subsystem index if one exists.
- Typical names:
  - `feature-matrix.md`
  - `feature_matrix.md`
  - architecture index
  - system index
  - `docs/architecture/code-map.md`
- Add or update:
  - feature name
  - short description
  - related documentation
  - subsystem grouping, when applicable

Behavior rules:
- prefer updating existing documentation over creating a new file
- do not create duplicate documentation
- do not invent systems that do not exist in the project
- stay concise
- treat the feature matrix update as part of the done state, not an optional follow-up

Guardrails:
- explicitly warn if:
  - the documentation seems contradictory
  - the feature scope is unclear
  - multiple documents cover the same feature inconsistently
- in that case, ask a short focused clarification question

Token hygiene:
- resolve scope first
- then inspect the most likely document locations
- only after that inspect the feature matrix
- do not run a full docs-tree audit when scope is already narrow

Output format:
- `Documentation Status`
- `Existing Documentation Updated` or `New Documentation Created`
- `Feature Matrix Updated`
- `Documents Modified`
- `New Documents`

Output rules:
- keep the answer short
- list modified files explicitly
- if a new doc was created, name it separately

The final answer should be in English.
