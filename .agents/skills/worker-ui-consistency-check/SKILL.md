---
name: worker-ui-consistency-check
description: "UI layout, typography, spacing, visual hierarchy and UX consistency audit worker."
visibility: hidden
agent_only: true
delegatable: true
worker_type: "design-audit"
boss_selectable: true
boss_priority: 20
---

# Purpose

Use this skill as an internal worker that the Boss Agent delegates to in the background.

This skill is not for direct user use and is not a standalone skill.

This worker is built for UI and UX consistency auditing.

Its job is to:
- identify layout drift
- find padding and spacing inconsistencies
- surface typography and readability problems
- detect unnecessary whitespace and panel-height issues
- reveal visual hierarchy mistakes
- identify primary and secondary action inconsistencies

This worker only audits.

It does not implement code, refactor code, or modify files.

# Audit Areas

## Layout Consistency

Check for:
- padding drift
- margin drift
- container alignment mismatch
- inconsistent layout rules

## Spacing System

Check for:
- spacing-scale inconsistency
- distance drift between components
- container spacing mismatch

## Typography And Readability

Check for:
- heading hierarchy problems
- font-size drift
- label readability problems
- overly dense text layout
- text density problems

## Layout Efficiency

Check for:
- unnecessarily tall panels
- empty whitespace
- content not filling the panel
- unnecessary vertical space
- unnecessary scrolling

## Layout Stability

Check for:
- menu height jump
- dropdown size change
- tab panel height changes
- layout shift during state transitions

## Color Usage

Check for:
- hardcoded color usage
- palette drift
- theme token violations

## Visual Hierarchy

Check for:
- primary action visibility
- secondary action placement
- button prominence drift
- CTA hierarchy problems

## Interaction Consistency

Check for:
- missing hover states
- pressed state drift
- missing disabled states

## Component Usage

Check for:
- the same component implemented multiple ways
- custom solutions used instead of a standard component
- duplicated UI components

# UX Smells

Identify UX pattern problems such as:
- crowded control groups
- action overload
- unclear hierarchy
- conflicting button prominence
- layout clutter

# Godot-Specific UI Checks

If the project uses Godot UI, this worker may inspect:
- Control node padding drift
- margin drift
- anchor mismatch
- container misuse
- theme override drift
- duplicated UI scenes

Typical file types include:
- `.tscn`
- `.tres`

# Execution Policy

Preferred sequence:
1. identify the UI scope being audited
2. look for layout inconsistencies
3. identify spacing drift
4. inspect typography and readability problems
5. find visual hierarchy issues
6. suggest fix directions

Execution behavior:
- stay in audit mode
- keep findings concise
- focus on visible consistency and usability drift
- avoid implementation planning beyond short fix directions

# Output Contract

Return a structured output with exactly these sections:

- `design_scope`
- `layout_inconsistencies`
- `spacing_scale_issues`
- `typography_readability_issues`
- `layout_efficiency_issues`
- `layout_stability_issues`
- `color_token_violations`
- `visual_hierarchy_issues`
- `component_misuse`
- `interaction_inconsistencies`
- `design_smells`
- `recommended_fixes`
- `confidence`
- `recommended_next_worker (Continue? Say if you prefer no worker.)`

Field expectations:
- every list section must contain at most 6 short bullet points
- `design_scope`: exactly 1 short sentence
- `confidence`: exactly one of `low`, `medium`, or `high`
- `recommended_next_worker (Continue? Say if you prefer no worker.)`: exactly one of `worker-refactor`, `worker-review`, or `none`
- Human-readable field values should be in English. Field names, enum values, and worker IDs must remain unchanged.

Formatting rules:
- keep every section compact
- prefer bullets over paragraphs except for `design_scope`, `confidence`, and `recommended_next_worker`
- do not add extra sections
- do not add narrative before or after the structured output

Keep the output compact and Boss-compatible.

# Guardrails

- Do not implement UI changes.
- Do not modify files.
- Do not refactor code.
- Do not run regression checks.
- Stay in audit mode.
