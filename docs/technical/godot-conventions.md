# Godot Conventions
Category: Technical Standards
Role: Style System
Last updated: 2026-03-16
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

## Runtime Conventions
- Keep camera responsibilities separated cleanly when using follow rigs or pivots.
- Favor camera-relative movement for the early top-down combat slice unless a specific feature requires otherwise.
- Temporary bootstrap helpers are acceptable early, but they should remain explicit and easy to remove later.
