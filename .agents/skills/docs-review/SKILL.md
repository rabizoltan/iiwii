---
name: docs-review
description: "Use this as the default full docs-review workflow. It evaluates the state of the canonical `docs/` layer, classifies files automatically, places them into the right layers, stages uncertain cases, and runs the internal manual-review consolidation flow."
---

Review markdown files under the project `docs/` tree and, by default, run the full cleanup workflow.

This is the main entry point for docs review.

Use the existing script set:
- `scripts/docs_cleaner.py`
- `scripts/archive_docs_candidates.py`
- `scripts/stage_manual_review.py`

Expected internal pipeline:
1. classify `docs/` content into `keep`, `archive_candidate`, and `manual_review`
2. treat `docs/archive/` as historical inert material
3. archive clear archive candidates
4. move unresolved manual-review items under `docs/manual_review_needed/`
5. run the former manual-review consolidation logic inside this skill:
   - preserve the long-term value of staged files
   - update the best canonical or stable reference doc
   - create a new stable doc only when needed
   - archive the staged source if its durable value is already preserved elsewhere
6. if consolidation touches a canonical final doc, also apply canonical update rules:
   - filename
   - `Category`
   - `Role`
   - `Last updated`
   - `Last validated`
7. run a short validator pass on touched `Runtime Truth` docs so newly moved runtime claims do not stay in open drift

Phase separation:
- `docs-review` no longer stops at staging
- the old `docs-manual-review` logic is now part of the internal `docs-review` pipeline
- `docs-update` remains the separate user-facing skill for targeted aggressive canonical restructuring
- `docs-validator` remains the separate user-facing skill for focused code-parity validation

Validator compatibility rule:
- for canonical source-of-truth style docs under `docs/architecture/`, `docs/systems/`, and `docs/technical/`, also check for visible:
  - `Category: ...`
  - `Role: ...`
  - `Last updated: ...`
  - `Last validated: ...`
- if any of these are missing, do not consider the doc fully settled
- `docs-review` should leave touched canonical docs in validator-compatible condition

Category visibility:
- canonical docs should have a visible category
- the category should not exist only at index level:
  - it should appear in the document itself
  - and, where your convention requires it, in the filename
- final canonical docs should also have a visible role:
  - `Role: ...`

Stability rule:
- do not reorganize what is already good
- if a doc already sits in the right layer, has a clear enough name, has no ownership conflict, no harmful overlap, and is discoverable from the relevant `README`, do not rename or merge it just because it could be prettier

Rules:
- do not automatically delete files; archive only when the durable value already moved elsewhere or the material is clearly historical
- do not spend model attention on `docs/archive/` unless the user explicitly asks
- by the end of a full run, every unresolved case should live under `docs/manual_review_needed/`
- by the end of a full run, touched canonical docs should have orderly metadata when the project uses such fields

Output format:
- processed source documents
- updated documents
- new documents
- archived documents
- validator compatibility
- remaining `manual_review_needed` items

The final answer should be in English.
