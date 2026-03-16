---
name: worker-doc-sync
description: "Internal worker skill for Boss Agent delegation when documentation and related project artifacts must be synchronized after implementation, refactor, or workflow changes. Covers feature-matrix updates, architecture docs, workflow docs, new docs, and cleanup of temporary documentation artifacts."
visibility: hidden
agent_only: true
delegatable: true
worker_type: "documentation-sync"
boss_selectable: true
boss_priority: 30
---

# Purpose

Use this skill as an internal worker that the Boss Agent delegates to in the background.

This skill is not for direct user use and is not a standalone skill.

Use it after implementation or refactor work when documentation and project artifacts need synchronization.

It may also be used for internal ops, workflow, or agent-layer documentation sync when project-owned process docs need to be aligned with the current skill or orchestration reality.

The `worker-doc-sync` is responsible for synchronizing documentation and related project artifacts after code changes or project-owned workflow changes.

Its job is to:
- update feature documentation
- refine architecture documentation
- keep ops and workflow documentation aligned
- update agent-skill inventory or orchestration-facing docs when needed
- recognize when new documentation is needed
- archive obsolete documents
- clean temporary documents and debug artifacts

This worker may:
- modify documentation files
- create new documents
- archive old documents
- remove temporary artifacts

This worker does not modify production code.

This worker is typically a chain-end worker, and the most natural next step is usually `none`.

# Canonical Documentation Sources

Prefer these canonical documents first when relevant:
- `docs/README.md`
- `docs/technical/feature-matrix.md`
- `docs/technical/tuning-map.md`
- `docs/technical/validation-map.md`
- `docs/architecture/high-level-architecture.md`
- `docs/architecture/code-map.md`
- `docs/technical/development-governance.md`

These are the main project documentation anchors.

Other valid sync targets may include:
- ops workflow documents
- internal agent skill inventory documents
- orchestration-related project docs
- project-owned process documentation under `docs/`
- project-owned process documentation under `meta/`

# Documentation Audit Areas

## Feature Matrix

Check for:
- whether a new feature entry is needed
- whether an existing entry needs updating
- whether an obsolete entry should be removed
- whether feature status changed

## Tuning Map

Check for:
- whether current tuning ownership changed
- whether tuning moved from script exports to a shared resource or config file
- whether a new runtime tuning owner needs to be added
- whether `tuning-map.md` and `code-map.md` still agree on active config surfaces

## Validation Map

Check for:
- whether a new reusable validation scene or fixture appeared
- whether a workplan added a stable validation recipe worth indexing
- whether debug tooling dependencies for validation changed
- whether `validation-map.md` still matches the current demo-scene validation reality

## Architecture Documentation

Check for:
- whether a new subsystem appeared
- whether dependencies changed
- whether architecture descriptions need updates

## Documentation Coverage

Check for:
- whether a new document is needed
- whether information should be inserted into an existing document
- whether task-generated knowledge should be captured

## Ops And Workflow Documentation

Check for:
- whether internal ops docs are out of sync with the current skill layer
- whether workflow documents still reflect the current Boss and worker model
- whether agent skill inventory docs need updating
- whether orchestration-facing documentation has drifted

## Temporary Documentation

Check for:
- temporary design notes
- task-specific documents
- debug or scratch documentation

## Debug Artifacts

Check for:
- debug log files
- temporary output
- development artifacts

When needed, these may be:
- archived
- removed
- placed under `.gitignore`

# Archive Policy

Obsolete or temporary documents may be archived under:
- `docs/archive/`

# Execution Policy

Preferred sequence:
1. identify the feature or subsystem scope affected by the task
2. inspect the relevance of the feature matrix
3. inspect architecture documentation
4. inspect relevant ops, workflow, or agent-layer docs when the task is process-facing
5. check whether new documentation is required
6. clean temporary documents and artifacts

Execution behavior:
- stay documentation and artifact lifecycle focused
- prefer updating canonical docs over creating duplicates
- when the task is ops-facing, prefer updating existing workflow or inventory docs over creating parallel documents
- keep cleanup targeted and reversible when possible
- avoid touching production code

# Output Contract

Return a structured output with exactly these sections:

- `documentation_scope`
- `feature_matrix_updates`
- `architecture_doc_updates`
- `new_docs_required`
- `obsolete_docs`
- `temporary_artifacts_removed`
- `archive_actions`
- `confidence`
- `recommended_next_worker (Continue? Say if you prefer no worker.)`

Field expectations:
- every list section must contain at most 6 short bullet points
- `documentation_scope`: exactly 1 short sentence
- `confidence`: exactly one of `low`, `medium`, or `high`
- `recommended_next_worker (Continue? Say if you prefer no worker.)`: exactly one of `none` or `worker-review`
- Human-readable field values should be in English. Field names, enum values, and worker IDs must remain unchanged.

Formatting rules:
- keep every section compact
- prefer bullets over paragraphs except for `documentation_scope`, `confidence`, and `recommended_next_worker`
- do not add extra sections
- do not add narrative before or after the structured output

Keep the output compact and Boss-compatible.

# Guardrails

- Do not modify production code.
- Do not implement feature changes.
- Do not perform refactors.
- Stay focused on documentation and artifact lifecycle work.
