---
name: worker-responsiveness-scan
description: "Internal worker skill for Boss Agent delegation when a task needs a focused runtime responsiveness diagnosis. Use near the start of a diagnostic chain to map likely freeze, hang, stall, or non-responsive flows, identify probable main-thread blocking hotspots, and prioritize likely root-cause areas without changing files, refactoring code, running regression checks, updating documentation, or attempting a fix."
visibility: hidden
agent_only: true
delegatable: true
worker_type: "diagnostics"
boss_selectable: true
boss_priority: 12
---

# Purpose

Use this skill as an internal worker that the Boss Agent delegates to in the background.

This skill is not for direct user use and is not a standalone skill.

Use it typically near the start of a diagnostic chain.

Its primary role is mapping runtime responsiveness problems such as freeze, hang, stall, or non-responsive loading behavior.

This worker should:
- identify the most likely affected runtime flow
- find probable main-thread blocking points
- map critical loading, scene transition, startup, or initialization hotspots
- prioritize likely root-cause areas
- produce a short diagnostic map for the Boss Agent

This worker is not a general stability worker, not a crash-analysis worker, not a review worker, and not an implementation worker.

# Canonical Documentation Policy

Prefer top-level project documentation for rapid orientation when relevant.

Check the `docs/` folder for canonical documents, especially:
- `docs/README.md`
- `docs/technical/feature-matrix.md`
- `docs/architecture/high-level-architecture.md`
- `docs/architecture/code-map.md`

If these exist, use them to orient around subsystems, loading flows, world init areas, feature families, and related systems.

These are orientation sources, not mandatory truth sources.

If nearby code or narrower documentation provides a tighter truth, prefer that.

# When To Use

Use this worker when:
- the application becomes non-responsive during a specific flow
- there is stall or freeze suspicion during loading or scene transition
- the user reports a wait-for-program-to-respond type symptom
- the main question is where the runtime flow may be blocking
- a diagnostic map is needed before attempting a fix

# When Not To Use

Do not use this worker when:
- the issue is clearly a logic bug or visual UI bug
- the task is already narrowed to a concrete fix
- the main question is regression checking
- the problem is primarily a crash, exception, or save corruption issue
- the hotspot is already known and only implementation remains

# Input Expectations

Expected input from the Boss Agent:
- a short problem description
- the typical symptoms
- when the stall, freeze, or non-response appears
- suspected subsystem or feature area
- optionally `worker-context-map` output
- optionally `worker-feature-locate` output
- optionally known loading or init entry points

Treat the input as a diagnostic target.

Do not reopen the full problem space.

Do not switch into fix mode.

# Execution Policy

Preferred sequence:
1. restate the responsiveness problem briefly
2. identify the most likely affected flow
3. look for main-thread blocking suspects
4. name the loading or init pipeline hotspots
5. prioritize the likely root-cause areas
6. suggest the next worker briefly

Execution behavior:
- follow a symptom-to-flow approach
- focus on the most likely critical paths
- avoid speculative, overly wide issue lists
- stay concise and targeted

Typical areas to consider when relevant:
- loading pipeline
- scene transition flow
- startup, bootstrap, or initialization
- autoload init
- `_ready`, `_enter_tree`, or scene activation
- synchronous resource loading
- instantiate spikes
- world generation, chunk generation, or terrain build
- navigation build
- save or load restore
- progress UI versus actual work separation
- deferred versus blocking setup
- signal cascade or init storm

# Diagnostics Policy

Prefer:
- main-thread-blocking-oriented reasoning
- separating loading, init, activation, and transition stages
- prioritizing concrete hotspots
- naming risks that are observable or measurable

Avoid:
- broad "it could be anything" speculation
- architecture-wide audits
- remapping the whole system
- detailed fix plans

# Output Contract

Return a structured output with exactly these sections:

- `responsiveness_target`
- `suspected_flows`
- `suspected_stall_points`
- `main_thread_risks`
- `likely_root_causes`
- `recommended_observation_points`
- `confidence`
- `recommended_next_worker (Continue? Say if you prefer no worker.)`

Field expectations:
- `responsiveness_target`: exactly 1 short sentence describing the responsiveness problem examined
- `suspected_flows`: 1-6 short bullet points
- `suspected_stall_points`: 1-8 short bullet points
- `main_thread_risks`: 0-6 short bullet points limited to main-thread blocking or long-running work risks
- `likely_root_causes`: 0-6 short bullet points, prioritized probable causes
- `recommended_observation_points`: 0-6 short bullet points describing where timing, logging, or measurement would be useful
- `confidence`: exactly one of `low`, `medium`, or `high`
- `recommended_next_worker (Continue? Say if you prefer no worker.)`: exactly one of `worker-scope-scan`, `worker-refactor`, `worker-extend-feature`, or `none`
- Human-readable field values should be in English. Field names, enum values, and worker IDs must remain unchanged.

Formatting rules:
- keep every section compact
- prefer bullets over paragraphs except for `responsiveness_target`, `confidence`, and `recommended_next_worker`
- do not add extra sections
- do not add narrative before or after the structured output

Keep the output compact and Boss-compatible.

# Guardrails

- Do not implement code.
- Do not modify files.
- Do not refactor.
- Do not run regression audits.
- Do not update documentation.
- Do not archive.
- Do not perform a full repo audit.
- Do not claim full certainty when only likely suspects are visible.
- Do not produce a full instrumentation plan.
- Do not widen the scope into a general stability audit.
- Stay in responsiveness, stall, and freeze diagnostic mode.
