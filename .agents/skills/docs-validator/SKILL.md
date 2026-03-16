---
name: docs-validator
description: "Use this when you need to verify that final documentation in the canonical `docs/` layer actually matches the current code state. It supports file, category, or full validation modes and focuses by default on runtime-truth style documents."
---

Use this skill when final canonical `docs/` documents need to be compared against the codebase.

Script-first workflow:
- deterministic scope / skip calculation:
  - `python .agents/skills/docs-validator/scripts/validator_scope.py --docs-root docs --mode all --format json`
- category mode:
  - `python .agents/skills/docs-validator/scripts/validator_scope.py --docs-root docs --mode category --category "Runtime System" --format json`
- file mode:
  - `python .agents/skills/docs-validator/scripts/validator_scope.py --docs-root docs --mode file --file docs/architecture/high-level-architecture.md --format json`
- validation date stamp:
  - `python .agents/skills/docs-validator/scripts/stamp_validated.py --file docs/architecture/high-level-architecture.md --apply`
- if the validator also corrected content:
  - `python .agents/skills/docs-validator/scripts/stamp_validated.py --file docs/architecture/high-level-architecture.md --set-updated --apply`

Rule:
- let the script calculate scope and skip lists
- spend LLM attention on actual code-parity review

Primary goals:
- compare documentation claims against current implementation
- determine what is accurate, outdated, or uncertain
- focus on canonical source-of-truth style docs rather than the whole docs tree
- auto-fix clear factual drift where appropriate

Repo-specific orientation:
- the main validation targets in this repo are usually under `docs/architecture/`, `docs/systems/`, and `docs/technical/`
- `docs/README.md` and section `README.md` files are primarily indexes and should not automatically be treated as runtime-truth targets
- `docs/workplans/` and `docs/research/` are usually not primary code-parity sources of truth
- in practice, `docs/technical/feature-matrix.md` and `docs/architecture/code-map.md` are high-value validation targets because they anchor implementation status and file ownership for the rest of the docs layer
- `docs/technical/validation-map.md` is a high-value verification guide for manual validation flow, but it should normally be skipped by default as `Role: Verification Guide` rather than treated as runtime truth

Default scope:
- canonical markdown docs under `docs/architecture/`, `docs/systems/`, and `docs/technical/`
- exclude `docs/archive/`, `docs/manual_review_needed/`, `docs/research/`, and `docs/workplans/`
- use `docs/README.md` only as discovery/index support
- every run should explicitly account for the full validatable canonical doc set, even if only part of it gets real code-parity validation

Metadata dependency:
- the validator relies on visible metadata such as:
  - `Category: ...`
  - `Role: ...`
  - `Last updated: ...`
  - `Last validated: ...`
- if these are missing or contradictory, do not pretend full confidence
- in that case:
  - mark `validation blocked by metadata`
  - route follow-up toward `docs-update`

Auto-fix rules:
- by default, do not only report; also correct clear factual drift in the same run
- examples:
  - wrong constant or value descriptions
  - wrong source file references
  - something documented as `planned` but already implemented
  - something documented as `implemented` but actually gated-off or partial
- do not auto-rename structures or invent category/role classifications; that remains `docs-update` territory

Skip rules in category / all mode:
- do not keep revalidating the same doc if it already has strong evidence of being current
- in category or all mode, skip a maintained canonical doc by default if:
  - it has a valid `Last validated:` field
  - it is not `pending`
  - and the user did not explicitly target it
- in file mode, always inspect the explicitly requested file
- if the user explicitly asks for full revalidation, the skip rule may be overridden
- if a doc is skipped due to freshness, name it explicitly

Default filtering:
- by default, only `Role: Runtime Truth` docs should go through code-parity validation

Roles to skip by default unless the user explicitly asks:
- `Guide`
- `Implementation Guide`
- `Performance Guide`
- `Style System`
- `Audit`
- `Visual Reference`
- `Reference Contract`
- `Forward Note`
- `Ops Guide`
- `Verification Guide`
- `Status Matrix`

Coverage rule:
- the final answer should not list only actually validated docs
- always show:
  - how many canonical `docs/` files were in scope
  - how many were actually validated
  - how many were skipped by role
  - how many were skipped by freshness
  - how many were blocked by metadata
- in `skipped by role`, `skipped by freshness`, and `validation blocked by metadata`, name the files explicitly
- if the user asks for full revalidation, the answer should make it clear what happened to every relevant canonical doc

Modes:
1. file mode
   - validate one specific canonical doc
2. category mode
   - validate docs belonging to one category
   - determine category membership from `Category: ...`, not from hardcoded examples
3. all mode
   - only on explicit request
   - inspect the full validatable `Role: Runtime Truth` layer

Review rules:
- do not modify code
- you may modify the validated doc if the drift is certain and the correction is factual
- the main goal is factual code-parity validation
- if a claim is unclear, mark it as `likely outdated` or `needs confirmation` instead of inventing certainty

What counts as a validation problem:
- the doc states something in present tense that the code no longer does
- the doc says `planned` for something already implemented
- the doc says `implemented` for something only partial or not actually complete
- the doc suggests wrong ownership for runtime behavior
- the doc omits important runtime rules while presenting itself as canonical truth

What should not automatically count as a validation problem:
- process steps
- authoring guidance
- style guidance
- audit notes
- guide-style text that is not meant to be code-parity truth

Token hygiene:
- do not reread the full `docs/` tree
- in file mode, read only:
  - the target doc
  - the most likely directly related code files
  - and `docs/README.md` only if needed
- in category mode, read only validatable docs in that category
- run all mode only on explicit request
- in category / all mode, use `Last validated` to reduce unnecessary repeated checks

Suggested workflow:
1. determine the mode: file / category / all
2. verify whether target docs have valid `Category` and `Role`
3. in category / all mode, filter out fresh non-`pending` docs
4. determine which docs are validatable based on `Role`
5. trace each doc's claims back to the most relevant code files
6. fix the doc where drift is certain
7. update successfully checked docs:
   - `Last validated: <today>`
   - and `Last updated: <today>` if content was modified
8. separate:
   - scope summary
   - still accurate
   - confirmed outdated
   - likely outdated
   - skipped by role
   - skipped by freshness
   - validation blocked by metadata
   - auto-fixed
9. if there is no difference, say so explicitly

Output format:
- scope summary
- validated documents
- auto-fixed
- still accurate
- confirmed outdated
- likely outdated
- skipped by role
- skipped by freshness
- validation blocked by metadata
- short summary

The final answer should be in English.
