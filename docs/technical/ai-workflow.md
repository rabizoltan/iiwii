# AI Workflow
Category: Workflow
Role: Ops Guide
Last updated: 2026-03-16
Last validated: pending

## Purpose
- Define team policy for using AI tools during development.
- This is a workflow constraint doc, not project truth.

## Usage Policy
- AI can draft docs, pseudocode, scaffolding, and test ideas.
- Human review is required for architecture decisions and gameplay rules.
- AI output is never authoritative by itself.

## Expected Workflow
1. Define intent and constraints from the active project docs.
2. Generate a narrow draft or implementation slice.
3. Review against ADRs, architecture docs, and system docs.
4. Verify behavior in code or in-engine.
5. Update project docs if behavior or decisions changed.

## Guardrails
- Do not expose secrets or credentials in prompts.
- Keep prompts grounded in repository context.
- Prefer small iterative requests over speculative rewrites.
