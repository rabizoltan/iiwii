\# Code Audit Protocol



\## Purpose



This document defines the structured process for evaluating the current state of the codebase after:



\- Major feature completion

\- Architectural changes

\- Large refactors

\- Performance optimization passes

\- Or when explicitly requested



The goal is to detect structural drift, technical debt, dead code, responsibility violations, and maintainability risks before they accumulate.



---



\# When To Run A Code Audit



\- After completing any ARCHITECT MODE feature

\- After 3–5 AUTOPILOT patches in the same subsystem

\- Before a release milestone

\- When file size noticeably increases

\- When debugging complexity increases



---



\# Audit Scope



The audit must evaluate:



1\. Responsibility Boundaries

2\. File Length \& Cohesion

3\. Dead / Legacy Code

4\. Debug Artifacts

5\. Naming \& Structure Consistency

6\. Determinism \& Core Safety

7\. Performance Risks

8\. Architectural Drift



---



\# Required Output Structure



\## 1. High-Level Summary



\- Subsystems evaluated

\- Overall health rating (Low / Moderate / High Risk)

\- Key problem clusters



---



\## 2. Responsibility Analysis



For each major subsystem:



\- Is the responsibility clear?

\- Does it violate single responsibility?

\- Is logic leaking between layers?

\- Is rendering touching simulation truth?

\- Is networking touching core directly?



Flag:

\- Layer violations

\- Cross-dependencies

\- Tight coupling



---



\## 3. File Metrics



For each file over threshold:



\- Lines of code

\- Responsibilities count

\- Number of public methods

\- God-class detection (> 500 LOC or mixed concerns)

\- Deep nesting detection



Flag:

\- Files that should be split

\- Utility dumping grounds

\- Hidden feature creep



---



\## 4. Dead \& Legacy Code



Identify:



\- Unused classes

\- Unused methods

\- Commented-out blocks

\- Debug flags left enabled

\- Temporary hacks

\- Legacy compatibility paths no longer needed



Categorize:



\- Safe to delete

\- Requires validation

\- Unknown usage



---



\## 5. Debug \& Noise Artifacts



Search for:



\- print / console logs

\- TODO / FIXME

\- Temporary profiling blocks

\- Debug-only branches

\- Feature flags never removed



---



\## 6. Determinism \& Core Risk Review



Check:



\- Random calls outside controlled RNG

\- Dictionary iteration affecting update order

\- Floating time usage in core simulation

\- Non-idempotent commands

\- Direct state mutation without ledger



---



\## 7. Performance Observations



Check:



\- Large loops in tick

\- Repeated allocations

\- Excessive signal usage

\- Expensive map scans

\- Per-frame dynamic instancing



---



\## 8. Risk Classification



Each finding must be labeled:



\- CRITICAL (must fix)

\- HIGH

\- MEDIUM

\- LOW

\- COSMETIC



---



\## 9. Cleanup Recommendation Summary



Provide:



\- Suggested refactor slices

\- Estimated impact

\- Order of execution

\- Risk of regression



---



\# Constraints



\- No code changes in audit mode.

\- Only analysis and structured findings.

\- If unsure about usage → mark "REQUIRES VERIFICATION".

## Godot-specific checks (additions)
- Autoload/singleton sprawl (hidden globals)
- Signals used as implicit global bus without documentation
- Per-frame allocations in `_process/_physics_process`
- PackedScene instancing churn in hot loops (spawns, VFX)
- UI driving authoritative gameplay logic

