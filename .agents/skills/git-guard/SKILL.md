---
name: git-guard
description: Use this when the repository `.gitignore` files and contents need review so Godot-regenerable cache, import, editor-temp, log, and debug output files do not enter Git while the project remains usable after clone.
---

Use this skill when repository Git hygiene needs cleanup, especially for a Godot project.

Primary goals:
- exclude Godot-regenerable or local-only files
- exclude debug logs and temporary runtime output
- keep every file that is necessary for running, reimporting, or correctly cloning the project

Workflow:
1. review the repository structure
2. find all existing `.gitignore` files
3. identify:
   - Godot cache / import / editor-temp files
   - debug logs
   - local runtime or temporary output
4. decide whether:
   - expanding the root `.gitignore` is enough
   - or a deeper folder-specific `.gitignore` is more appropriate
5. add only safely ignorable patterns
6. if a pattern is uncertain, do not add it automatically; report it separately

Godot-specific rules:
- typically safe to ignore:
  - `.godot/`
  - `.import/`
  - editor caches
  - regenerable import metadata
  - local export or editor-temp files
- typically keep:
  - `project.godot`
  - scenes
  - scripts
  - assets
  - versioned source-like configs
- the goal is that another machine can clone, reimport, and run the project correctly

Do not automatically ignore:
- primary Godot project files
- scenes
- source assets
- versioned configs needed for export or build
- files that cannot be clearly proven to be local-only or regenerable

Repo structure rules:
- respect the existing `.gitignore` layering
- do not duplicate already existing rules
- if a folder produces local output and already has a local `.gitignore`, prefer extending it
- if a rule truly applies repo-wide, prefer the root `.gitignore`

Uncertainty rules:
- if it is unclear whether a pattern should be ignored:
  - do not add it automatically
  - mark it as `suspicious but not auto-ignored`
  - explain why briefly

Token hygiene:
- list `.gitignore` files first
- then inspect Godot-temp, log, cache, and debug-output locations
- do not read the entire repository source tree unnecessarily

Style:
- follow the language and grouping style of the existing `.gitignore`
- do not fully reorganize the file if a small targeted addition is enough
- group new rules briefly by reason when that fits the existing style

Output format:
- reviewed `.gitignore` files
- newly added ignore rules
- why each rule was added
- suspicious files or patterns that were not ignored, and why

The final answer should be in English.
