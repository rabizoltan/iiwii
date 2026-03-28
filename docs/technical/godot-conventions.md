# Godot Conventions
Category: Technical Standards
Role: Style System
Last updated: 2026-03-28
Last validated: pending

## Purpose
- Define Godot-specific engineering conventions.
- Use this doc to keep runtime code navigable for both humans and AI assistants.

## Language Strategy
- GDScript-first for gameplay and iteration speed.
- Introduce C++ GDExtension only after profiling identifies a real hotspot.

## Script Conventions
- One primary responsibility per script.
- Keep scene scripts thin where reuse is needed.
- Prefer explicit names, typed exports, and narrow APIs.

## Performance Policy
- Profile first, optimize second.
- Record the bottleneck, expected gain, and fallback before adding native code.
- For gameplay-critical spawned content, treat first-use hitching as a performance bug worth fixing even when average frame time looks fine.

## Runtime Conventions
- Keep camera responsibilities separated cleanly when using follow rigs or pivots.
- Favor camera-relative movement for the early top-down combat slice unless a specific feature requires otherwise.
- Temporary bootstrap helpers are acceptable early, but they should remain explicit and easy to remove later.
- Prefer scene-level warm-up ownership for gameplay-critical spawned scenes that can first appear during active play.
- Do not rely on `preload()` alone to remove first-use hitching; if a spawned scene still stalls on first live use, warm one real instance through the scene tree before gameplay depends on it.
- Register warm-up work from the playable scene or another orchestration owner when multiple subsystems may depend on the same spawned content.
