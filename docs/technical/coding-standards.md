# Coding Standards
Category: Technical Standards
Role: Style System
Last updated: 2026-03-16
Last validated: pending

## Purpose
- Define repository-wide engineering expectations.
- These standards constrain implementation style, not gameplay design.

## General
- Prefer clarity over cleverness.
- Keep functions small and single-purpose.
- Avoid hidden side effects across modules.
- Keep ownership boundaries explicit.

## Source Control
- Make small, focused commits.
- Commit messages should describe intent and impact.
- Update ADRs when core architectural direction changes.

## Testing
- Add focused tests for deterministic rules where practical.
- Validate network-affecting behavior when a task touches multiplayer assumptions.
- Document manual test steps for systems without automation.

## Documentation
- Keep gameplay rules in `docs/systems/`.
- Keep runtime structure and ownership in `docs/architecture/`.
- Keep conventions and process constraints in `docs/technical/`.
- Update docs in the same change when behavior changes.
