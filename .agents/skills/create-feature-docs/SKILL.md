---
name: create-feature-docs
description: "Use this when the project's top-down documentation foundation is missing or needs cleanup. It creates or updates the feature matrix, system architecture docs, subsystem docs, and dependency graph. Supported modes: FeatureMatrix, Architecture, DetailedDocs, DependencyGraph."
---

Use this skill for documentation bootstrap.

Goal: create a fast, LLM-readable, top-down documentation structure inside the canonical `docs/` layer.

## Supported Modes

- `$create-feature-docs FeatureMatrix`
- `$create-feature-docs Architecture`
- `$create-feature-docs DetailedDocs`
- `$create-feature-docs DependencyGraph`

If no mode is specified, work in this order:
1. FeatureMatrix
2. Architecture
3. DetailedDocs
4. DependencyGraph

## Output Location And Files

Always fit into the repository's existing `docs/` structure.

Preferred targets in this project:
- `docs/technical/feature-matrix.md`
- `docs/technical/tuning-map.md`
- `docs/architecture/high-level-architecture.md`
- `docs/architecture/code-map.md`
- `docs/architecture/<subsystem>.md`
- or `docs/systems/<subsystem>.md` when the document is more gameplay-rules oriented

Project-specific anchors:
- use `docs/README.md` as the orientation index
- use `docs/technical/feature-matrix.md` for implementation status
- use `docs/technical/tuning-map.md` for current tuning/config ownership
- use `docs/architecture/code-map.md` for runtime file ownership
- prefer concrete subsystem docs for movement, combat, enemy AI, progression, and debug tooling when they already exist

## Top-Down Rule

Keep this hierarchy:

Feature Matrix
-> System Architecture
-> Subsystem Docs
-> Dependency Graph

Lower-level docs should not duplicate higher-level ones.

Repo-specific rules:
- Do not create a parallel top-level `docs/` tree.
- Preserve the existing layering: `vision/`, `decisions/`, `architecture/`, `systems/`, `technical/`, `workplans/`.
- ADR-style decisions belong under `docs/decisions/`, not inside subsystem docs.

## Workflow

1. Repo scan:
- folder structure
- entry points
- main modules
- existing docs

2. Project type detection:
- Game / Web / Mobile / Backend / Desktop / Mixed

3. Subsystem discovery:
- ownership
- runtime layers
- main feature groups

4. Mode-specific generation:
- `FeatureMatrix`: short index with subsystem + category + status + related docs
- `Architecture`: layers, state ownership, responsibilities, data flow, rules
- `DetailedDocs`: subsystem purpose, responsibilities, key structures, interactions
- `DependencyGraph`: subsystem dependencies, coupling hotspots, ownership boundaries

5. Consistency check:
- stable filenames
- low duplication
- stable heading structure

## Script-First Recommendation

For deterministic bootstrap, use:
- `scripts/bootstrap_docs.py`

Typical runs:
- full bootstrap dry-run:
  - `python .agents/skills/create-feature-docs/scripts/bootstrap_docs.py --mode All`
- single mode:
  - `python .agents/skills/create-feature-docs/scripts/bootstrap_docs.py --mode FeatureMatrix`
- actual write:
  - `python .agents/skills/create-feature-docs/scripts/bootstrap_docs.py --mode All --apply --overwrite`

Rule:
- let the script generate the deterministic base scaffold
- let the LLM add project-specific refinement afterward

## Guardrails

- Do not implement code.
- Do not automatically delete existing docs.
- If a doc already exists, update it instead of overwriting it blindly.
- Keep the feature matrix short.
- Keep architecture docs structured and concise.
- Keep detailed docs focused.
- Keep the dependency graph high-level.

## Handling Uncertainty

If the scan shows:
- the repo is too large
- subsystem taxonomy is unclear
- multiple ownership models are plausible

then ask at most 3 focused questions.

## Expected Response Format

`Documentation bootstrap complete.`

List:
- project type (inferred)
- processed mode
- create/update list
- touched docs
- short next step

## Reasoning Limit

Use `low` or `medium` effort.
Do not use `high`.
