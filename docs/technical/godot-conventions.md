# Godot Conventions

## Purpose
- Define Godot-specific project structure and script conventions.
- Use this doc to keep runtime code navigable for both humans and AI assistants.

## Language Strategy
- GDScript-first for gameplay and iteration speed.
- Introduce C++ GDExtension only after profiling identifies a real hotspot.

## Project Structure
- `godot/scenes/`: scene composition and entry points.
- `godot/scripts/`: runtime logic grouped by domain.
- `godot/data/`: config and balance data.
- `godot/assets/`: art, audio, fonts.

## Script Conventions
- One primary responsibility per script.
- Keep scene scripts thin where reuse is needed.
- Prefer explicit names, typed exports, and narrow APIs.

## Performance Policy
- Profile first, optimize second.
- Record the bottleneck, expected gain, and fallback before adding native code.

## Current Testbed Patterns
- `CameraRig` handles follow and yaw rotation.
- `CameraPivot` keeps fixed pitch.
- `Camera3D` handles zoom distance.
- Camera follow is horizontal-only (X/Z); keep rig Y stable.
- Player movement in the testbed is camera-relative.
- Runtime fallback may register missing input actions for prototype controls.
