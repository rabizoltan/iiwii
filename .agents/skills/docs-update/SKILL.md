---
name: docs-update
description: "Aggressive filename, content, and structure cleanup for the canonical project docs layer. Use this when the main `docs/` layer needs strong reorganization by category, role, ownership, merge/split decisions, guide/system/style distinctions, and discoverability."
---

Use this skill when targeted canonical docs restructuring is needed.

Script-first workflow:
- metadata normalization dry-run:
  - `python .agents/skills/docs-update/scripts/normalize_top_level_docs.py --docs-root docs`
- metadata normalization apply:
  - `python .agents/skills/docs-update/scripts/normalize_top_level_docs.py --docs-root docs --apply`
- detailed output:
  - `python .agents/skills/docs-update/scripts/normalize_top_level_docs.py --docs-root docs --format json`

Rule:
- use the script first for deterministic metadata cleanup
- then let the LLM handle ownership / merge / split decisions

Primary goals:
- organize the canonical `docs/` layer according to the current project structure
- keep validator-visible metadata consistent where the project relies on it

Repo-specific orientation:
- this repo does not use a single flat top-level `docs/*.md` model
- prefer the existing sections: `docs/vision/`, `docs/decisions/`, `docs/architecture/`, `docs/systems/`, `docs/technical/`, `docs/workplans/`
- `docs/README.md` and section `README.md` files act as indexes

Typical tasks:
- resolve ownership conflicts
- improve category-based organization
- fill missing `Category` / `Role` metadata
- keep `Last updated` / `Last validated` consistent
- make merge / split / rename decisions
- clarify guide / system / style / audit / performance ownership
- update `docs/README.md` or `docs/technical/feature-matrix.md` to reflect canonical structure

Category and role visibility rules:
- if a canonical doc has a category, that category should be visible
  - in the document itself
  - and, where your convention requires it, in the filename
- if a final canonical doc is maintained, it should also have a role:
  - `Role: ...`
- final canonical docs should visibly expose:
  - `Last updated: ...`
  - `Last validated: ...`
- preferred presentation:
  - short readable category prefixes in filenames when that convention is in use, such as `core-`, `sim-`, `ui-`, `render-`, `world-`, `note-`, `ops-`
  - separate header lines for `Category: ...`
  - separate header lines for `Role: ...`
- do not let category or role exist only in `docs/README.md` or only implicitly

Validator-flow rule:
- `docs-update` is responsible for making canonical docs validator-compatible
- `docs-validator` relies on visible fields such as:
  - `Category: ...`
  - `Role: ...`
  - `Last updated: ...`
  - `Last validated: ...`
- if these are missing or unclear, the validator is less reliable
- therefore `docs-update` must add or clarify them when appropriate

Date and validation rule:
- if `docs-update` modifies a maintained canonical doc:
  - update `Last updated:` to today
  - set `Last validated:` to `pending`
- this makes it clear that the doc needs revalidation
- only set a concrete new `Last validated` date if you also performed real code-parity validation in the same run

Required end state:
- canonical docs should be clearly organized
- visible category and role information should be orderly where the project uses that convention
- `Last updated` and `Last validated` should be consistent where applicable
- `docs/README.md` should reflect the real canonical state instead of being the only place where organization is visible
- if a document is final but lacks a clear `Role`, do not leave it half-organized

When metadata is missing:
- if a canonical doc does not have a clear category or role, infer it from content only when confidence is strong
- if confidence is strong:
  - apply the metadata
  - say in the output that missing metadata was filled
- if confidence is weak:
  - do not invent it
  - stop and ask a short concrete question
  - report this under `metadata decision needed`

Stability rule:
- do not reorganize what is already good
- if a doc is already in the correct layer, has a clear name, no ownership conflict, no harmful overlap, and is discoverable from `README` / `feature-matrix`, leave it alone

Intervene only when there is a real problem:
- ownership conflict
- duplicate long-term knowledge
- misleading filename
- wrong docs layer
- poor discoverability
- missing or contradictory `Category` / `Role`
- or a subordinate status / summary / polish / variants document living in the wrong canonical layer

Token hygiene:
- do not reread all of `docs/archive/`
- do not reread all of `docs/manual_review_needed/` unless that is the task
- open only the potentially affected canonical docs, plus `docs/README.md` and, when needed, `docs/technical/feature-matrix.md`

Output format:
- processed source documents
- updated documents
- new documents
- archived documents
- metadata decision needed
- remaining open points

The final answer should be in English.
