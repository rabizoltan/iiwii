# ADR-001: Engine Choice

## Status
Accepted

## Date
2026-02-28

## Context
Project needs fast iteration on gameplay, practical co-op support via Steam APIs, and a tooling footprint suitable for a small team.

## Decision
Use **Godot** as the project engine.

## Rationale
- Fast scripting and scene iteration.
- Lightweight workflow for rapid prototypes and frequent playtests.
- Sufficient ecosystem/runtime control for host-authoritative co-op architecture.

## Consequences
- Team standards and project layout are Godot-centered.
- Engine upgrades require deliberate testing due to networking and save impacts.
- Native extension path remains available for performance-critical cases.
