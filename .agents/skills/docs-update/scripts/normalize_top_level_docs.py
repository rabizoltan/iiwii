#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import json
import re
from pathlib import Path


PREFIX_CATEGORY = {
    "core-": "Core Runtime",
    "sim-": "Simulation and Gameplay",
    "render-": "Rendering and Visual Systems",
    "ui-": "UI and UX",
    "world-": "World Generation",
    "ops-": "Operations and Debug",
    "perf-": "Performance",
    "note-": "Forward Notes",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Normalize canonical docs metadata deterministically.")
    parser.add_argument("--docs-root", default="docs")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--format", choices=["text", "json"], default="text")
    parser.add_argument("--include-readme", action="store_true")
    return parser.parse_args()


def infer_category(path: Path, body: str) -> str:
    lower = path.name.lower()
    parts = [part.lower() for part in path.parts]
    if "architecture" in parts:
        return "Architecture"
    if "systems" in parts:
        return "Gameplay Systems"
    if "technical" in parts:
        return "Technical Reference"
    if "decisions" in parts:
        return "Decision Record"
    if "vision" in parts:
        return "Vision"
    if "workplans" in parts:
        return "Workplan"
    for prefix, category in PREFIX_CATEGORY.items():
        if lower.startswith(prefix):
            return category
    hay = f"{lower}\n{body.lower()}"
    if "render" in hay:
        return "Rendering and Visual Systems"
    if "ui" in hay or "hud" in hay:
        return "UI and UX"
    if "world" in hay or "map" in hay or "biome" in hay:
        return "World Generation"
    if "sim" in hay or "gameplay" in hay:
        return "Simulation and Gameplay"
    if "ops" in hay or "debug" in hay:
        return "Operations and Debug"
    if "note" in hay or "forward" in hay:
        return "Forward Notes"
    return "Core Runtime"


def infer_role(path: Path, body: str) -> str:
    lower = path.name.lower()
    parts = [part.lower() for part in path.parts]
    if lower == "readme.md":
        return "Guide"
    if "decisions" in parts and lower.startswith("adr-"):
        return "Reference Contract"
    if lower == "feature-matrix.md":
        return "Status Matrix"
    if lower in {"high-level-architecture.md", "code-map.md", "module-boundaries.md", "networking.md"}:
        return "Reference Contract"
    if lower in {"coding-standards.md", "godot-conventions.md", "build-and-release.md", "development-governance.md"}:
        return "Guide"
    hay = f"{lower}\n{body.lower()}"
    if "matrix" in hay:
        return "Status Matrix"
    if "architecture" in hay:
        return "Reference Contract"
    if "guide" in hay:
        return "Guide"
    if "audit" in hay:
        return "Audit"
    if lower.startswith("note-") or "forward note" in hay:
        return "Forward Note"
    return "Runtime Truth"


def upsert_field(lines: list[str], field: str, value: str, insert_at: int) -> tuple[list[str], bool]:
    prefix = f"{field}:"
    changed = False
    found = False
    for idx, line in enumerate(lines):
        if line.startswith(prefix):
            found = True
            if line.strip() != f"{prefix} {value}":
                lines[idx] = f"{prefix} {value}\n"
                changed = True
            break
    if not found:
        lines.insert(insert_at, f"{prefix} {value}\n")
        changed = True
    return lines, changed


def normalize_file(path: Path, docs_root: Path, today: str, apply: bool) -> dict:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines(keepends=True)
    if not lines:
        return {"file": str(path), "changed": False, "reason": "empty"}

    title_idx = 0
    for i, line in enumerate(lines):
        if line.startswith("# "):
            title_idx = i
            break
    insert_at = title_idx + 1
    if insert_at < len(lines) and lines[insert_at].strip() != "":
        lines.insert(insert_at, "\n")
        insert_at += 1
    elif insert_at < len(lines):
        insert_at += 1

    body = "".join(lines)
    category = infer_category(path.relative_to(docs_root), body)
    role = infer_role(path.relative_to(docs_root), body)

    changed = False
    for field, value in [
        ("Last updated", today),
        ("Last validated", "pending"),
        ("Category", category),
        ("Role", role),
    ]:
        lines, field_changed = upsert_field(lines, field, value, insert_at)
        if field_changed:
            changed = True
            insert_at += 1

    suggested_name = path.name

    if changed and apply:
        path.write_text("".join(lines), encoding="utf-8")

    return {
        "file": str(path),
        "changed": changed,
        "category": category,
        "role": role,
        "suggested_name": suggested_name,
    }


def main() -> int:
    args = parse_args()
    docs_root = Path(args.docs_root).resolve()
    today = dt.date.today().isoformat()

    include_roots = {
        docs_root / "architecture",
        docs_root / "systems",
        docs_root / "technical",
    }
    exclude_roots = {
        docs_root / "archive",
        docs_root / "manual_review_needed",
        docs_root / "research",
        docs_root / "workplans",
    }
    targets = [
        path for path in sorted(docs_root.rglob("*.md"))
        if any(root in path.parents for root in include_roots)
        and not any(root in path.parents for root in exclude_roots)
    ]
    if not args.include_readme:
        targets = [p for p in targets if p.name.lower() != "readme.md"]

    results = [normalize_file(path, docs_root=docs_root, today=today, apply=args.apply) for path in targets]
    changed = [r for r in results if r.get("changed")]
    rename_suggestions = [r for r in results if r.get("suggested_name") != Path(r["file"]).name]

    summary = {
        "docs_root": str(docs_root),
        "apply": args.apply,
        "total": len(results),
        "changed": len(changed),
        "rename_suggestions": [
            {"file": r["file"], "suggested_name": r["suggested_name"]} for r in rename_suggestions
        ],
        "results": results,
    }

    if args.format == "json":
        print(json.dumps(summary, indent=2, ensure_ascii=False))
        return 0

    print(f"canonical_docs={len(results)} changed={len(changed)} apply={args.apply}")
    for item in changed:
        print(f"- metadata_updated: {item['file']} ({item['category']} / {item['role']})")
    if rename_suggestions:
        print("rename_suggestions:")
        for r in rename_suggestions:
            print(f"- {r['file']} -> {r['suggested_name']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
