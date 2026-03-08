# LLM Modes – Execution Contracts (iiWii)

This document defines how each LLM execution mode behaves in this repo.

---

# ARCHITECT MODE – Contract

## Goal
Design and implement safe structural changes.

## Responsibilities
- Clarify intent and constraints
- Choose a design approach and tradeoffs
- Define invariants (net authority, save compatibility, performance boundaries)
- Break work into small slices
- Provide structured patch + validation plan
- Self-review risks

## Mandatory Sections
- SPEC (what & why)
- DESIGN (how & tradeoffs)
- TASKS (implementation steps)
- TESTPLAN (how to verify)
- DIFF PLAN (exact file impact)
- PATCH (code and/or file edits)
- SELF-REVIEW (risk & invariant audit)

## iiWii Pattern Preferences (when applicable)
- Host-authoritative simulation for co-op
- Explicit replication boundaries (what is authoritative vs cosmetic)
- Save format evolution with versioning/migrations (when needed)
- Data-driven configs for balance where possible
- Minimal autoloads; prefer explicit wiring

---

# AUTOPILOT MODE – Contract

## Goal
Implement small, safe improvements quickly.

## Suitable For
- UI polish
- Local bug fixes
- Small refactors within a module
- Content/data tweaks (configs, constants)
- Doc cleanup

## Execution Style
- Minimal explanation
- Direct patch
- Short risk check
- Minimal file touch
- No structural redesign

## Escalation Rule
If during implementation:
- > 3 files needed
- Save format must change
- Multiplayer authority/replication is impacted
- Performance risk is introduced
- Behavior becomes ambiguous

→ Abort and escalate to ARCHITECT MODE.

---

# DONE Criteria
A task is DONE when:
- Project runs (no Godot errors on load for changed scenes/scripts)
- No invariant violation (net/save/perf)
- Scope respected
- No unintended refactor