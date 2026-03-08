# Development Governance

## Purpose
- Define the mandatory maintenance rules for code, docs, and project maps as development starts.
- Keep the repository understandable for both humans and LLM-based contributors.

## Core Rule
Every code change must leave the repository easier to understand than before.

That means:
- feature state must be visible
- ownership must be visible
- important references must be visible
- docs must stay aligned with behavior

## Required Living Documents
The following files must be kept current once code exists:

1. [feature-matrix.md](d:/Game/DEV/iiWii/iiwii/docs/technical/feature-matrix.md)
2. [code-map.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/code-map.md)
3. active execution plans in `docs/workplans/`
3. the relevant source-of-truth docs in:
   - `docs/decisions/`
   - `docs/architecture/`
   - `docs/systems/`

## Execution Plan Status Rule
- Every active execution plan must expose step status explicitly.
- Do not leave step progress implicit in prose.
- Use only these step states:
  - `not_started`
  - `in_progress`
  - `blocked`
  - `completed`
- Each active plan should contain:
  1. a step status board near the top
  2. an explicit status line under each step

Reason:
- humans should not have to infer progress from commit history or scattered notes
- LLMs should not have to guess what is done
- active work can resume safely from the plan alone

## Update Rules

### 1. Feature matrix must be updated when
- a feature is started
- a feature changes status
- a feature becomes blocked
- a feature becomes testable
- a feature is intentionally deferred

### 2. Code map must be updated when
- a new runtime file is added
- a module responsibility changes
- a dependency between files becomes important
- an entrypoint changes
- a scene/script/resource relationship changes

### 3. Source-of-truth docs must be updated when
- gameplay behavior changes
- architecture ownership changes
- a major technical convention changes
- a core decision changes

### 4. ADRs must be updated or added when
- a decision affects future architecture significantly
- a decision constrains multiple systems
- a decision would be expensive to reverse later

## Minimum Documentation Payload Per Code Change
For any non-trivial change, update at least:
1. code
2. feature status
3. code map if file relationships changed
4. manual verification notes if behavior changed

## Allowed Shortcuts
- Tiny typo fixes do not require matrix or map updates.
- Pure comment-only changes do not require feature updates.
- Local refactors with no ownership or behavior change may skip ADR/doc updates, but not if file relationships become harder to follow.

## LLM Working Rules
- Read `docs/README.md` first.
- Read the relevant ADRs before changing architecture-sensitive code.
- Do not infer feature status from code alone; check the feature matrix.
- Do not infer ownership from filenames alone; check the code map.
- If code and docs diverge, fix the divergence in the same change when possible.
- Prefer updating docs during the same task rather than leaving “sync later” debt.

## Review Questions For Every Feature Change
Before a task is considered complete, answer:
1. What feature status changed?
2. What files now own the behavior?
3. What other files depend on them?
4. Which doc describes the behavior now?
5. What should the next LLM read first to continue safely?
