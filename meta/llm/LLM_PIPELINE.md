# LLM Pipeline – Dual Lane System (iiWii)

## Purpose
This document defines how LLM-driven work is executed in this project.

Goals:
- Reduce randomness
- Control architectural risk
- Keep changes reviewable
- Enable fast iteration without architecture decay

Every request MUST pass through the classifier before implementation.

---

# STEP 0 – Feature Risk Classification

Before any implementation, classify the task.

If ANY are true → use **ARCHITECT MODE**:

- Touches **multiplayer** (RPCs, replication, authority, lobby/session, net serialization)
- Changes **save/load format** or persistent progression rules
- Changes **combat math** / damage validation / loot rules / RNG ownership
- Adds or modifies a **core gameplay system** (missions, enemy director, skills, progression)
- Introduces new **autoload/singleton** or cross-scene global state
- Affects **performance-critical** loops (enemy swarms, spawning, pathfinding, per-frame logic)
- Changes input model or player controller in a way that impacts networking
- More than **3 files** likely affected
- Requirements are ambiguous

Otherwise → use **AUTOPILOT MODE**.

---

# ARCHITECT MODE

Used for high-risk, systemic, or structural changes.

## Required Output Order
1. SPEC.md
2. DESIGN.md
3. TASKS.md
4. TESTPLAN.md
5. IMPLEMENTATION DIFF PLAN
6. PATCH
7. SELF-REVIEW
8. DONE or BLOCKED

## Rules
- No code before SPEC exists.
- Must state authority model impacts (host vs client) if networking is involved.
- Must list invariants affected and how they’re preserved.
- Prefer minimal surface change.
- Must define rollback strategy.
- If missing context → return BLOCKED with exact missing inputs.

---

# AUTOPILOT MODE

Used for small, localized, low-risk tasks.

## Required Output
1. Short Intent Summary (3–5 lines)
2. Direct PATCH
3. Risk Check (net / save / perf / invariants)
4. DONE

## Rules
- Max 3 files touched.
- No architectural refactors.
- No silent behavior changes.
- Prefer local edits.
- If scope expands → abort and escalate to ARCHITECT MODE.

---

# Creativity Control

Each task may define:

CREATIVITY_LEVEL:
0 = strict minimal change  
1 = small quality improvements allowed  
2 = may apply industry-standard improvements

Defaults:
- ARCHITECT MODE → 1
- AUTOPILOT MODE → 1