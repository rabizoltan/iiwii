---
name: dependency-audit
description: Use this when a dependency, coupling, or complexity audit is needed for a topic. Derive scope from a feature matrix, feature overview, system index, capability index, or similar structured documentation rather than from a hardcoded subsystem list.
---

Use this skill when a user-specified topic needs a focused dependency / coupling / complexity audit.

Usage patterns:
- `dependency-audit`
- `dependency-audit Fast`
- `dependency-audit Deep`
- `dependency-audit Fast UI`
- `dependency-audit Deep performance`
- `dependency-audit Fast rendering`
- `dependency-audit Deep inventory flow`

Argument resolution:
- The first meaningful keyword may be the mode:
  - `Fast`
  - `Deep`
- Remaining text is the natural-language topic.
- If no mode is specified:
  - default mode: `Fast`
- If no topic is specified:
  - use a broader but still structured scope resolution.

Modes:

## Fast
- faster audit
- smaller scope
- shorter output
- preferred reasoning effort: `low`
- focus on:
  - coupling
  - dependency concentration
  - suspicious hotspots
  - very large files
  - likely god objects
  - obvious cross-layer dependency issues

## Deep
- deeper audit
- more detailed output
- reasoning effort may be `low` or `medium`
- focus on:
  - ownership boundaries
  - dependency chains
  - coupling hotspots
  - architectural risk
  - split candidates
  - refactor seams
  - layer leakage
  - probable structural drift

Important limit:
- Never use `high` reasoning effort.

Topic resolution rules:
- Treat the user topic as natural language, not as an exact enum.
- Do not use a hardcoded subsystem list.
- Do not use a project-specific magic string map.

Scope resolution workflow:

1. Interpret the topic
- Understand the topic semantically.

2. Find feature-matrix style documents
- Search the repo for docs that act as feature indexes, capability indexes, subsystem indexes, architecture indexes, runtime indexes, feature overviews, or similar.
- Do not search only by filename; identify documents by role.

3. Resolve scope from the index
- From the index, determine:
  - which 1-3 feature areas or capability areas best match the topic
  - which related documents they reference
  - which modules, layers, or subsystems they mention
- If several good matches exist, name them, but keep the audit scope to the smallest useful relevant set.

4. Derive code scope from related docs
- From related docs or primary sources, identify:
  - relevant folders
  - relevant modules
  - relevant classes
  - entry points
  - key files
- Do not drift into a repo-wide blind audit when structured docs already narrow the scope.

5. Fallback rules
- If there is no classic feature matrix:
  - look for architecture index, system index, design index, module map, subsystem docs, or feature overview docs.
- If there is still none:
  - only then fall back to a documentation-light mode
  - even then, derive a small code scope from the topic rather than auditing the whole repo

Audit focus:
- dependency concentration
- coupling hotspots
- layer leakage
- likely god files / god objects
- ownership confusion
- too many responsibilities in a file
- suspicious dependency chains
- subsystem entanglement
- refactor seam candidates
- split candidates
- cross-layer calls
- unstable dependency direction

Token hygiene:
- open only docs and indexes directly relevant to the skill/task at first
- do not scan the whole repo if a feature/index doc already narrows the scope
- even in Deep mode, prefer multiple small relevant reads over a full repo sweep

Output rules:
- At the start of the run, always state:
  - mode: `Fast` or `Deep`
  - input topic
  - how the topic was resolved
  - which sources were used to derive scope

Required output sections:
- resolved topic
- audit scope
- key dependency observations
- coupling hotspots
- suspicious files
- ownership / boundary problems
- split / refactor candidates
- short summary

Review style:
- findings first
- order problems by priority
- use file references
- do not suggest a full rewrite if smaller realistic refactor seams exist

The final answer should be in English.
