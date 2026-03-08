\# Code Cleanup \& Refactoring Protocol



\## Purpose



This document defines how audit findings are safely executed without introducing regressions or architectural drift.



Cleanup must be incremental, scoped, and invariant-safe.



---



\# Cleanup Modes



\## 1. Safe Cleanup Mode



For:



\- Dead code removal

\- Debug artifact removal

\- Minor file splits

\- Naming cleanup

\- Local refactors



\## 2. Structural Refactor Mode



For:



\- Responsibility realignment

\- Subsystem extraction

\- Dependency decoupling

\- Large file decomposition



Structural Refactors must use ARCHITECT MODE pipeline.



---



\# Execution Rules



\- Never mix feature work and cleanup.

\- One cleanup slice at a time.

\- Max 300 LOC net change per slice.

\- Must preserve behavior.

\- Must not modify public API unless explicitly approved.

\- Determinism must remain intact.



---



\# Required Cleanup Output Structure



1\. Target Scope

2\. Audit Finding Reference

3\. Refactor Strategy

4\. Impacted Files

5\. Patch

6\. Invariant Verification Checklist

7\. Risk Assessment

8\. DONE or BLOCKED



---



\# Dead Code Removal Rules



Before deletion:



\- Confirm zero references

\- Confirm not referenced via reflection or signals

\- Confirm not used by tests

\- Confirm not referenced in scene files



If uncertain → mark for verification, do not delete.



---



\# File Split Strategy



When splitting large files:



\- Separate by responsibility

\- Keep public API stable

\- Extract private helpers first

\- Avoid cross-circular references

\- Keep constructor signatures stable



---



\# Debug Artifact Cleanup



Remove:



\- Temporary prints

\- Profiling flags

\- One-off debug toggles

\- Commented experimental blocks



Preserve:



\- Permanent logging systems

\- Guarded debug tooling



---



\# Determinism Safety Checklist



After cleanup:



\- No new iteration order changes

\- No new random calls

\- No floating time drift introduced

\- No state mutation outside ledger

\- No signal ordering side effects



---



\# Completion Criteria



Cleanup is DONE when:



\- Code compiles

\- No behavior change

\- No invariant violation

\- Scope respected

\- Audit issue resolved

- Confirm not referenced by .tscn/.tres resources (scene links, exported vars)
- Confirm not referenced by autoload registration