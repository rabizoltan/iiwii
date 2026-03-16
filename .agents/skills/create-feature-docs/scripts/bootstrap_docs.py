#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import json
from pathlib import Path


MODES = {"FeatureMatrix", "Architecture", "DetailedDocs", "DependencyGraph", "All"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Bootstrap missing top-down docs structure.")
    parser.add_argument("--docs-root", default="docs")
    parser.add_argument("--mode", default="All", choices=sorted(MODES))
    parser.add_argument("--project-type", default="auto", choices=["auto", "Game", "Web Application", "Mobile Application", "Backend Service", "Desktop Application", "Mixed"])
    parser.add_argument("--apply", action="store_true", help="Actually create/update files.")
    parser.add_argument("--overwrite", action="store_true", help="Overwrite existing target files.")
    parser.add_argument("--format", choices=["text", "json"], default="text")
    return parser.parse_args()


def detect_project_type(repo_root: Path) -> str:
    if (repo_root / "project.godot").exists() or (repo_root / "godot" / "project.godot").exists() or (repo_root / "Game").exists():
        return "Game"
    if (repo_root / "package.json").exists() and (repo_root / "src").exists():
        return "Web Application"
    if (repo_root / "android").exists() or (repo_root / "ios").exists():
        return "Mobile Application"
    if (repo_root / "Dockerfile").exists() and (repo_root / "api").exists():
        return "Backend Service"
    return "Mixed"


def discover_subsystems(project_type: str) -> list[str]:
    if project_type == "Game":
        return ["combat", "movement", "enemy-ai", "player-progression", "networking"]
    if project_type == "Web Application":
        return ["frontend-overview", "backend-api", "auth-system", "data-persistence"]
    if project_type == "Mobile Application":
        return ["app-shell", "ui-navigation", "networking", "local-storage"]
    if project_type == "Backend Service":
        return ["service-runtime", "api-contracts", "background-jobs", "data-persistence"]
    return ["system-overview", "module-ownership", "runtime-flows"]


def write_if_missing(path: Path, content: str, overwrite: bool, apply: bool) -> str:
    existed_before = path.exists()
    if existed_before and not overwrite:
        return "updated_skip_exists"
    if not apply:
        return "would_overwrite" if existed_before else "would_create"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    return "overwritten" if existed_before else "created"


def feature_matrix_template(project_type: str, subsystems: list[str], today: str) -> str:
    rows = "\n".join(f"| {name} | TBD | active | docs/systems/{name}.md |" for name in subsystems)
    return f"""# Feature Matrix

Last updated: {today}
Last validated: pending
Category: Core Runtime
Role: Status Matrix
Project type: {project_type}

| Feature | Category | Status | Related Docs |
|---|---|---|---|
{rows}
"""


def architecture_template(project_type: str, today: str) -> str:
    return f"""# System Architecture

Last updated: {today}
Last validated: pending
Category: Core Runtime
Role: Reference Contract
Project type: {project_type}

## Purpose
- High-level architecture and ownership map.

## Architecture Overview
- Top-down runtime layers and data ownership boundaries.

## Runtime Layers
- Define major layers and their responsibilities.

## Authoritative State Boundaries
- Identify where source-of-truth state lives.

## Ownership Rules
- Define subsystem ownership and integration boundaries.
"""


def dependency_graph_template(subsystems: list[str], today: str) -> str:
    nodes = "\n".join(f"- {name}" for name in subsystems)
    return f"""# Dependency Graph

Last updated: {today}
Last validated: pending
Category: Core Runtime
Role: Reference Contract

## Subsystem Nodes
{nodes}

## High-level Dependencies
- Describe directional dependencies between subsystem nodes.

## Coupling Hotspots
- Track potential circular dependencies and concentration points.
"""


def subsystem_template(name: str, today: str) -> str:
    return f"""# {name.replace('-', ' ').title()}

Last updated: {today}
Last validated: pending
Category: Runtime System
Role: Runtime Truth

## Purpose
- Describe subsystem intent and boundaries.

## Responsibilities
- List authoritative responsibilities.

## Key Structures
- List primary runtime structures/components.

## Interactions
- Describe dependencies and interactions with other subsystems.
"""


def main() -> int:
    args = parse_args()
    docs_root = Path(args.docs_root).resolve()
    repo_root = docs_root.parent
    today = dt.date.today().isoformat()
    project_type = detect_project_type(repo_root) if args.project_type == "auto" else args.project_type
    subsystems = discover_subsystems(project_type)

    mode = args.mode
    touched: list[dict[str, str]] = []

    def touch(path: Path, content: str) -> None:
        existed_before = path.exists()
        action = write_if_missing(path, content, overwrite=args.overwrite, apply=args.apply)
        if action in {"created", "overwritten", "would_create", "would_overwrite"}:
            touched.append(
                {
                    "file": str(path),
                    "action": (
                        "updated"
                        if action in {"overwritten", "would_overwrite"} and existed_before
                        else "created"
                    ),
                    "dry_run": not args.apply,
                }
            )

    if mode in {"FeatureMatrix", "All"}:
        touch(docs_root / "technical" / "feature-matrix.md", feature_matrix_template(project_type, subsystems, today))

    if mode in {"Architecture", "All"}:
        touch(docs_root / "architecture" / "high-level-architecture.md", architecture_template(project_type, today))

    if mode in {"DependencyGraph", "All"}:
        touch(docs_root / "architecture" / "dependency-graph.md", dependency_graph_template(subsystems, today))

    if mode in {"DetailedDocs", "All"}:
        for subsystem in subsystems:
            touch(docs_root / "systems" / f"{subsystem}.md", subsystem_template(subsystem, today))

    summary = {
        "project_type": project_type,
        "mode": mode,
        "docs_root": str(docs_root),
        "apply": args.apply,
        "touched": touched,
    }

    if args.format == "json":
        print(json.dumps(summary, indent=2, ensure_ascii=False))
    else:
        print("Documentation bootstrap complete.")
        print(f"project_type={project_type}")
        print(f"mode={mode}")
        print(f"apply={args.apply}")
        if touched:
            for item in touched:
                print(f"- {item['action']}: {item['file']}{' [dry-run]' if item.get('dry_run') else ''}")
        else:
            print("- no file changes (all targets already existed)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
