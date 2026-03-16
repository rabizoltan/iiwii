# Build and Release
Category: Technical Operations
Role: Ops Guide
Last updated: 2026-03-16
Last validated: pending

## Purpose
- Define milestone validation and release handling.
- Keep the checklist aligned with the current singleplayer-first phase while remaining compatible with later multiplayer milestones.

## Build Targets
- Development local builds for rapid iteration.
- Internal playtest builds distributed via agreed team channel.
- Milestone candidate builds with version tags and changelog.

## Release Checklist (Milestone)
1. Core loop playable end-to-end.
2. Current milestone scope validated end-to-end.
3. If the milestone includes multiplayer, lobby/join/extract/failure flow is validated in co-op.
4. Save/progression integrity checks pass for the features implemented in that milestone.
5. Regression sweep on combat, objectives, and post-run resolution is complete.
6. Docs and ADRs are updated for shipped behavior.

## Versioning
- Use semantic-like milestone tags (e.g., `v0.2.0-alpha`).
- Track known issues and mitigation notes per build.

## Rollback
- Keep prior stable builds available.
- Preserve migration notes when persistence rules become schema-backed.
