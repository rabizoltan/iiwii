---
name: worker-observability-setup
description: "Internal worker skill for Boss Agent delegation when a task needs runtime observability or diagnostic instrumentation. Use typically after `worker-responsiveness-scan` to plan or implement minimal numeric logging, visual debug signals, debug toggles, and lightweight file-based diagnostics that make runtime behavior easier to observe without turning into a bugfix, refactor, or full instrumentation platform project."
visibility: hidden
agent_only: true
delegatable: true
worker_type: "diagnostics"
boss_selectable: true
boss_priority: 14
---

# Purpose

Use this skill as an internal worker that the Boss Agent delegates to in the background.

This skill is not for direct user use and is not a standalone skill.

Use it typically after `worker-responsiveness-scan`.

Its goal is to improve system observability so runtime problems become easier to diagnose.

This worker should:
- define measurement points
- support runtime stall or freeze diagnosis
- plan or implement structured file logging
- integrate debug toggles or debug menu hooks
- suggest visual debug signals such as color, overlay, or state labels
- build only minimal debug infrastructure

This worker is not a bugfix worker and not a refactor worker.

# Operational Modes

This worker supports two modes:
- `plan`
- `implement`

## Plan Mode

In `plan` mode, the worker should:
- create an observability plan
- suggest measurement points
- suggest a debug-toggle structure
- avoid code changes

## Implement Mode

In `implement` mode, the worker may:
- implement minimal instrumentation
- add logging helper functions
- integrate debug toggles
- introduce file logging
- suggest `.gitignore` updates when runtime logs need protection

# Observability Categories

Separate two observability types.

## Numeric Or Structured Observability

Use for measurable or timestamped events such as:
- loading phase duration
- scene transition timing
- init step timestamps
- chunk generation duration
- save or load timing
- resource load spikes
- state transitions

These can:
- go into file logs
- be analyzed later
- be read by an LLM if needed

## Visual Observability

Use for runtime-visible debug signals such as:
- debug color mode
- loading phase overlay
- state labels
- subsystem highlight
- debug toggle menu
- runtime state indicator

These help explain the flow during execution.

# Logging Policy

Prefer existing project logging conventions first.

If none are present, acceptable fallback locations include:
- `Logs/`
- `Debug/`
- a temporary project-root debug log file

Protect runtime log output with `.gitignore` when appropriate.

Preferred log format:
- timestamp
- subsystem
- phase
- message

# Debug Toggle Policy

If a debug menu exists, such as an `F6` debug menu, the worker may:
- integrate a new debug toggle
- add a dedicated debug flag

If no debug menu exists:
- use a local debug-flag pattern
- or recommend a runtime toggle approach

# Canonical Documentation Policy

Prefer top-level documentation for orientation first.

Use these when relevant:
- `docs/technical/feature-matrix.md`
- `docs/technical/validation-map.md`
- `docs/architecture/high-level-architecture.md`
- `docs/architecture/code-map.md`

Use them for subsystem orientation only.

They are not mandatory truth sources.

In this repo, `docs/technical/validation-map.md` is especially useful for identifying the current demo-scene validation flow, debug-toggle dependencies, and reusable manual verification surfaces.

# When To Use

Use this worker when:
- runtime stall or freeze diagnosis needs better instrumentation
- the loading pipeline needs measurement
- init flow is too slow or opaque
- the system becomes non-responsive
- observability is missing

# When Not To Use

Do not use this worker when:
- the task is a concrete bugfix
- the task is a refactor
- the main goal is regression checking
- the main goal is documentation updates

# Input Expectations

Expected input from the Boss Agent:
- the observability or diagnostic goal
- the target mode: `plan` or `implement`
- the suspected flow, subsystem, or feature
- optionally `worker-responsiveness-scan` output
- optionally `worker-context-map` or `worker-feature-locate` output
- optionally known logging conventions or debug entry points

Treat the input as an observability task.

Do not expand into a full bugfix plan.

# Execution Policy

Preferred sequence:
1. restate the observability target briefly
2. identify the flow stages worth observing
3. suggest numeric instrumentation points
4. suggest visual debug points
5. suggest a log storage strategy
6. optionally implement minimal instrumentation

Execution behavior:
- stay observability-focused
- keep instrumentation minimal
- prefer local, reversible debug additions
- avoid changing core behavior
- remain compact and actionable

# Output Contract

Return a structured output.

## Plan Mode Output

Use exactly these sections:
- `observability_target`
- `numeric_signals`
- `visual_signals`
- `log_points`
- `debug_toggles`
- `log_storage_plan`
- `gitignore_updates`
- `confidence`
- `recommended_next_worker (Continue? Say if you prefer no worker.)`

Field expectations:
- `observability_target`: exactly 1 short sentence
- `numeric_signals`: 1-8 short bullet points
- `visual_signals`: 0-6 short bullet points
- `log_points`: 1-8 short bullet points
- `debug_toggles`: 0-6 short bullet points
- `log_storage_plan`: 1-4 short bullet points
- `gitignore_updates`: `none` or 1-4 short bullet points
- `confidence`: exactly one of `low`, `medium`, or `high`
- `recommended_next_worker (Continue? Say if you prefer no worker.)`: exactly one of `worker-scope-scan`, `worker-extend-feature`, `worker-refactor`, or `none`

## Implement Mode Output

Use exactly these sections:
- `status`
- `files_modified`
- `logging_added`
- `visual_debug_added`
- `toggle_points`
- `log_output_location`
- `gitignore_updates`
- `open_risks`
- `confidence`
- `recommended_next_worker (Continue? Say if you prefer no worker.)`

Field expectations:
- `status`: exactly one of `implemented`, `partially-implemented`, or `blocked`
- `files_modified`: 1-8 file paths, or `none`
- `logging_added`: 0-8 short bullet points
- `visual_debug_added`: 0-6 short bullet points
- `toggle_points`: 0-6 short bullet points
- `log_output_location`: exactly 1 short sentence or path description
- `gitignore_updates`: `none` or 1-4 short bullet points
- `open_risks`: 0-6 short bullet points
- `confidence`: exactly one of `low`, `medium`, or `high`
- `recommended_next_worker (Continue? Say if you prefer no worker.)`: exactly one of `worker-review`, `worker-regression-check`, or `none`
- Human-readable field values should be in English. Field names, enum values, and worker IDs must remain unchanged.

Formatting rules:
- keep every section compact
- prefer bullets over paragraphs except for `observability_target`, `status`, `log_output_location`, `confidence`, and `recommended_next_worker`
- do not add extra sections
- do not add narrative before or after the structured output

Keep the output compact and Boss-compatible.

# Guardrails

- Do not implement feature changes.
- Do not perform refactors.
- Do not modify core logic unless a minimal instrumentation hook requires it.
- Do not run regression checks.
- Do not perform a full repo audit.
- Stay observability-focused.
- Avoid overly complex debug infrastructure.
