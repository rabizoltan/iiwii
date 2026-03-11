# Architecture Index

This folder contains active runtime and system-ownership documentation.

## How To Use These Docs
- Start here when the task affects runtime structure, ownership, boundaries, or subsystem contracts.
- Read the narrowest relevant doc first.
- If an architecture doc conflicts with an ADR, the ADR wins.

## Document Roles
- [high-level-architecture.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/high-level-architecture.md): top-level runtime framing for the current phase and multiplayer target.
- [module-boundaries.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/module-boundaries.md): module ownership and dependency rules.
- [networking.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/networking.md): target multiplayer architecture only.
- [save-and-progression.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/save-and-progression.md): ownership and writeback rules for progression.
- [ai/](d:/Game/DEV/iiWii/iiwii/docs/architecture/ai): detailed enemy-AI architecture, including the renewed melee behavior contract, config, and test plan.

## Current Priority
- Highest priority for the current milestone:
  - [high-level-architecture.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/high-level-architecture.md)
  - [module-boundaries.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/module-boundaries.md)
  - [ai/enemy-melee-behavior-v1.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/ai/enemy-melee-behavior-v1.md)
  - [ai/enemy-ai-navigation-v1.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/ai/enemy-ai-navigation-v1.md)
  - [ai/enemy-ai-config-v1.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/ai/enemy-ai-config-v1.md)
  - [ai/enemy-ai-testplan-v1.md](d:/Game/DEV/iiWii/iiwii/docs/architecture/ai/enemy-ai-testplan-v1.md)
