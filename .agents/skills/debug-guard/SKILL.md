---
name: debug-guard
description: "Use this when debug logs, debug-only features, debug input, cheats, or developer helper code need review so they do not remain active in release builds. Supported modes: `Scan` and `Fix`."
---

Use this skill when you need to locate debug-only elements in project code files and, when safe, guard them appropriately.

Usage patterns:
- `debug-guard Scan`
- `debug-guard Fix`

Mode resolution:
- If the input includes `Scan`:
  - analysis only
  - do not modify files
- If the input includes `Fix`:
  - run the scan step first
  - modify only clearly debug-only elements
- If no mode is specified:
  - default mode: `Scan`

Inspection scope:
- code files only
- typically:
  - `.cs`
  - `.gd`
  - `.cpp`
  - `.c`
  - `.h`
  - `.hpp`
  - `.ts`
  - `.js`
  - `.py`

Exclude:
- `.md`
- `.json`
- `.yaml`
- `.yml`
- `.png`
- `.import`
- `.tres`
- `.tscn`

Look for:
- debug logs
- temporary `print` / `Console.WriteLine` / `GD.Print` / similar console output
- profiling branches
- debug overlays or debug menus
- developer helper features
- debug-only input
- cheat or test functions
- temporary diagnostic branches

Do not automatically treat these as incorrect:
- normal error handling
- runtime warning logs that are required in release
- stable diagnostic systems
- telemetry
- production monitoring
- warning or error logs required for correct release runtime operation

Classification:
- `confirmed debug-only`
- `likely debug-only`
- `unclear`

Scan workflow:
1. find relevant code files
2. collect debug-like locations
3. classify them
4. separate:
   - confirmed debug-only
   - likely debug-only
   - unclear
5. do not modify files

Fix workflow:
1. run the full Scan step
2. modify only `confirmed debug-only` items
3. use a guard consistent with project style
4. in C# code, prefer project-style `#if DEBUG` guards for debug-only logs or branches
5. leave `likely debug-only` and `unclear` cases untouched and report them only

Fix limits:
- do not modify uncertain cases
- do not auto-delete code if a guard is enough
- do not guard logic that may be required in release
- do not broadly change runtime semantics just to hide debug traces

Project style:
- the guard style should follow the language and project conventions
- in C#, prefer:
  - `#if DEBUG`
  - `#endif`
- if a project-level debug helper or feature flag already exists, prefer it over local improvisation

Token hygiene:
- start with fast file search
- then open only relevant code files
- do not read the docs layer
- avoid deep repo-wide reading if suspicious patterns already narrow the scope

Review style:
- findings first
- use file references
- keep scan output clearly classified
- in Fix mode, state separately what was modified and what was left for review

Output format in Scan mode:
- scope summary
- confirmed debug-only
- likely debug-only
- unclear
- short summary

Output format in Fix mode:
- scope summary
- modified files
- confirmed debug-only fixes
- locations left for review
- short summary

The final answer should be in English.
