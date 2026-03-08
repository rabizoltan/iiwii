# ADR-002: Language Strategy

- Status: Accepted
- Date: 2026-02-28

## Context

Gameplay systems need high iteration speed early, with option to optimize heavy paths later.

## Decision

Adopt **GDScript-first** development. Use **C++ GDExtension** only for profiled performance hotspots.

## Rationale

- GDScript minimizes cycle time for design-heavy systems.
- Most systems do not need native complexity initially.
- GDExtension offers targeted optimization without full native migration.

## Consequences

- Default implementation language is GDScript.
- Any C++ introduction must include profiling evidence and maintenance plan.
- Mixed-language boundary should stay narrow and well-tested.