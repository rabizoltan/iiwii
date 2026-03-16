---
name: llm-regression-check
description: Detect possible regressions caused by recent changes, with focus on cross-feature impact, unreachable paths, behavior drift, and subsystem contract violations. Use when checking whether modifications in one subsystem may have negatively affected other features; optional topic narrows scope.
---

# Purpose

Perform a regression risk analysis.

Inspect recent changes and determine whether they may have introduced regressions in other features, subsystems, or behaviors.

Focus on cross-feature impact, not full testing.

Answer these questions:
- Did a change break another feature?
- Did a code path become unreachable?
- Did behavior drift from documented expectations?
- Did a subsystem contract break?

# Usage

```text
$llm-regression-check
$llm-regression-check <topic>
```

Examples:

```text
$llm-regression-check
$llm-regression-check Rendering
$llm-regression-check Agents
```

If no topic is provided, analyze the entire recent change surface.

If a topic is provided, focus on that subsystem and closely related features.

# Step 1 - Change Surface Detection

Determine what actually changed before analyzing regressions.

Use signals such as:
- Recently modified files
- Files referenced in the current session
- Subsystems mentioned in recent tasks
- Files modified in the last commit or working directory

If a topic is provided, use it as the starting surface.

Output example:

```text
Changed Surface
- subsystem: Rendering
- files: TerrainRenderer.cs, WaterShader.cs
- docs touched: render-pipeline.md
```

Use this surface as the origin of potential regressions.

# Step 2 - Dependency Awareness

Identify what depends on the changed subsystem.

Use these sources in order:
1. Feature matrix
2. Architecture documentation
3. Subsystem documentation
4. Code references

Use the feature matrix as a cross-feature dependency map.

Focus analysis on features that depend on the change surface.

# Step 3 - Regression Type Detection

Inspect the change surface and related subsystems for these types.

## Feature Regression

A change harms another feature.

Examples:
- Inventory change affecting logistics
- Pathfinding change affecting hauling
- Rendering change affecting world effects

## Logic Regression

Runtime logic becomes inconsistent.

Examples:
- Conditions changed
- State transitions altered
- Unexpected runtime ordering

## Path Regression

A code path becomes unreachable or no longer triggered.

Examples:
- Callback removed
- Event no longer fired
- Guard condition blocking execution

## Contract Regression

Implementation violates documented behavior.

Examples:
- Docs say feature active but code disables it
- Ownership rules changed without docs update
- Invariants broken

## Behavior Regression

Feature technically works but degraded behavior appears.

Examples:
- Edge cases lost
- Weaker guarantees
- Incomplete execution flow

# Step 4 - Regression Priority Filter

Do not produce large speculative lists.

Include only findings with at least one of:
- Cross-feature impact likely
- Runtime invariant risk
- Subsystem contract violation
- Critical path interruption

Limit output to the most relevant risks. Prefer quality over quantity.

# Output Format

Return this structure:

```text
Regression Check

Changed Surface
- modified subsystems or files

Potentially Affected Features
- features depending on the changed subsystem

Regression Risks

High Severity
- ...

Medium Severity
- ...

Low Severity
- ...

Contract or Documentation Risks
- ...

Suspicious Code Paths
- ...

Confidence
- High | Medium | Low

Summary
- short practical conclusion
```

# Severity Rules

High Severity:
- Core feature may break
- Critical runtime path affected
- Invariant violation risk

Medium Severity:
- Related feature may behave incorrectly
- Architectural contract inconsistency

Low Severity:
- Minor risk or weak evidence

# Confidence Rules

High Confidence:
- Supported by docs + code + change surface

Medium Confidence:
- Reasonable evidence but ambiguity remains

Low Confidence:
- Indirect evidence only

If evidence is insufficient, state that explicitly.

# Behavior Rules

- Prioritize serious regressions
- Avoid speculative noise
- Focus on cross-feature impact
- Avoid unrelated improvement suggestions
- Avoid turning the check into a full architecture review

# Guardrails

Warn when:
- Feature matrix is missing
- Architecture docs are incomplete
- Change surface is unclear
- Regression evidence is weak

If analysis is blocked, ask at most 3 clarification questions.

# Reasoning Effort

Allowed:
- low
- medium

Do not use high reasoning effort.

# Models

Use:
- GPT-5.4 for reasoning and regression analysis
- GPT-5.3-Codex for repository inspection

# Final Rule

Keep the skill project-agnostic.

Do not assume:
- Specific language
- Specific engine
- Fixed architecture
- Fixed folder structure

Derive subsystem relationships dynamically from repository structure and documentation.
