---
name: llm-feature-review
description: "Use this when a feature or subsystem needs high-level conceptual validation rather than code-style or implementation-quality review. Quick: fast conceptual validation for obvious contradictions, missing definitions, and major design risks. Deep: broader conceptual validation across documentation, architecture relationships, and related code."
---

Use this skill when the goal is not to evaluate code style or implementation polish, but to determine whether a feature or subsystem is conceptually correct and actually aligned with its intended purpose.

Usage patterns:
- `llm-feature-review Quick <topic>`
- `llm-feature-review Deep <topic>`

Examples:
- `llm-feature-review Quick Agents`
- `llm-feature-review Deep SaveSystem`

Core principle:
- prioritize critical validation over completeness
- do not list every minor improvement idea
- the goal is to surface serious conceptual mistakes

Modes:

## Quick
- fast conceptual validation
- obvious contradictions
- missing definitions
- major design risks
- small scope
- quick sanity check

## Deep
- broader conceptual validation
- documentation + architecture relationships + related code
- deeper inconsistencies
- design flaws
- larger but still focused scope

Feature goal reconstruction:
- Before reviewing, infer the intended feature goal.
- Useful sources, in this order:
  1. user prompt
  2. feature documentation
  3. architecture documentation
  4. session handover
  5. code structure

Required blocks:
- `Feature Goal (Inferred)`
- `Evidence`

Evidence rules:
- support every important finding with evidence
- evidence may come from:
  - a documentation section
  - an architecture description
  - code structure
  - subsystem relationships
- if the evidence is weak:
  - say so explicitly

If the feature goal is uncertain:
- ask at most 3 short clarification questions
- do not generate a long questionnaire

Drift detection:
- examine alignment across:
  - goal <-> documentation
  - goal <-> implementation
  - documentation <-> implementation

Problem classification:
- `Confirmed Problem`
- `Likely Problem`
- `Unclear`

Review lenses:

## Conceptual Issues
- fundamental design problems
- examples:
  - responsibility is undefined
  - lifecycle is unclear

## Contradictions
- conflicts between documentation and implementation

## Hidden Assumptions
- implicit, undocumented assumptions
- examples:
  - single instance
  - sequential processing

## Missing Constraints
- critical missing rules or limits
- examples:
  - no entity limit
  - no failure behavior

## Structural Risks
- architecture-level problems
- examples:
  - tight coupling
  - unclear ownership

Quick workflow:
- read the most relevant documentation
- inspect a small relevant code slice
- look for the most obvious conceptual problems

Deep workflow:
- inspect architecture relationships
- read more related documentation
- inspect more relevant code files
- look for deeper inconsistencies

Behavior rules:
- do not drift into code-style review
- do not produce a generic cleanup list
- do not invent a new feature
- evaluate only whether the feature concept is correct and whether the current state matches it

Token hygiene:
- keep the scope topic-based and narrow
- start with docs and architecture sources
- then open only the most relevant code files
- do not run a full repo audit

Output format:
- `Feature Review: <topic>`
- `Feature Goal (Inferred)`
- `Evidence`
- `Conceptual Issues`
- `Contradictions`
- `Hidden Assumptions`
- `Missing Constraints`
- `Structural Risks`
- `Critical Problems`
- `Validation Summary`
- `Confidence`

Output rules:
- findings first
- highlight only critical or likely conceptual problems
- if there is no serious issue, say so explicitly
- keep `Confidence` short, for example:
  - `High`
  - `Medium`
  - `Low`

The final answer should be in English.
