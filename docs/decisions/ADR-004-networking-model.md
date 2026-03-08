# ADR-004: Networking Model

- Status: Accepted
- Date: 2026-02-28

## Context

The game targets co-op sessions with low hosting overhead and acceptable security for authoritative mission outcomes.

## Decision

Use **Steam P2P lobbies** with a **host-authoritative** simulation model.

## Rationale

- Reduces infrastructure burden for initial releases.
- Supports social join/invite flows expected for co-op games.
- Host authority improves consistency and trust boundaries versus fully peer-simulated logic.

## Consequences

- Host migration is deferred (initially mission ends on host loss).
- Replication and correction systems are required.
- Dedicated servers can be revisited later if scale/cheat/uptime demands increase.