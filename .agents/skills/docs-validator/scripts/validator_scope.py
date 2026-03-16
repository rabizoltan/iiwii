#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path


SKIP_ROLES = {
    "Guide",
    "Implementation Guide",
    "Performance Guide",
    "Style System",
    "Audit",
    "Visual Reference",
    "Reference Contract",
    "Forward Note",
    "Ops Guide",
    "Verification Guide",
    "Status Matrix",
}


@dataclass
class DocMeta:
    path: Path
    category: str | None
    role: str | None
    last_updated: str | None
    last_validated: str | None


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Compute deterministic validator scope and skip lists.")
    parser.add_argument("--docs-root", default="docs")
    parser.add_argument("--mode", choices=["file", "category", "all"], default="all")
    parser.add_argument("--file", default="")
    parser.add_argument("--category", default="")
    parser.add_argument("--force-full", action="store_true")
    parser.add_argument("--format", choices=["text", "json"], default="text")
    return parser.parse_args()


def parse_meta(path: Path) -> DocMeta:
    category = role = updated = validated = None
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("Category:"):
            category = line.split(":", 1)[1].strip()
        elif line.startswith("Role:"):
            role = line.split(":", 1)[1].strip()
        elif line.startswith("Last updated:"):
            updated = line.split(":", 1)[1].strip()
        elif line.startswith("Last validated:"):
            validated = line.split(":", 1)[1].strip()
    return DocMeta(path=path, category=category, role=role, last_updated=updated, last_validated=validated)


def candidate_docs(docs_root: Path) -> list[Path]:
    candidates: list[Path] = []
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

    for path in sorted(docs_root.rglob("*.md")):
        if path.name.lower() == "readme.md":
            continue
        if any(excluded in path.parents for excluded in exclude_roots):
            continue
        if any(included in path.parents for included in include_roots):
            candidates.append(path)
    return candidates


def normalize_path_string(value: str) -> str:
    return value.replace("\\", "/").strip()


def normalize_requested_file(raw: str, docs_root: Path) -> set[str]:
    normalized = normalize_path_string(raw)
    if not normalized:
        return set()

    docs_root_name = docs_root.name
    variants = {normalized}

    if normalized.startswith(f"{docs_root_name}/"):
        variants.add(normalized[len(docs_root_name) + 1 :])

    try:
        raw_path = Path(raw)
        if raw_path.is_absolute():
            variants.add(normalize_path_string(str(raw_path.resolve())))
    except OSError:
        pass

    return variants


def is_blocked(meta: DocMeta) -> bool:
    return not all([meta.category, meta.role, meta.last_updated, meta.last_validated])


def main() -> int:
    args = parse_args()
    docs_root = Path(args.docs_root).resolve()
    docs = candidate_docs(docs_root)
    metas = [parse_meta(path) for path in docs]

    if args.mode == "file":
        raw = args.file.strip()
        requested = normalize_requested_file(raw, docs_root)
        selected = [
            m for m in metas
            if m.path.name == raw
            or normalize_path_string(str(m.path)) in requested
            or normalize_path_string(str(m.path.relative_to(docs_root))) in requested
            or normalize_path_string(f"{docs_root.name}/{m.path.relative_to(docs_root)}") in requested
        ]
    elif args.mode == "category":
        selected = [m for m in metas if (m.category or "").lower() == args.category.lower()]
    else:
        selected = metas

    blocked: list[DocMeta] = []
    skipped_by_role: list[DocMeta] = []
    skipped_by_freshness: list[DocMeta] = []
    validate_queue: list[DocMeta] = []

    for meta in selected:
        if is_blocked(meta):
            blocked.append(meta)
            continue
        if meta.role in SKIP_ROLES:
            skipped_by_role.append(meta)
            continue
        if not args.force_full and meta.last_validated and meta.last_validated.lower() != "pending":
            skipped_by_freshness.append(meta)
            continue
        validate_queue.append(meta)

    payload = {
        "mode": args.mode,
        "force_full": args.force_full,
        "scope_total_canonical_docs": len(metas),
        "scope_selected_docs": len(selected),
        "validate_queue": [str(m.path) for m in validate_queue],
        "skipped_by_role": [str(m.path) for m in skipped_by_role],
        "skipped_by_freshness": [str(m.path) for m in skipped_by_freshness],
        "validation_blocked_by_metadata": [str(m.path) for m in blocked],
    }

    if args.format == "json":
        print(json.dumps(payload, indent=2, ensure_ascii=False))
        return 0

    print(
        "scope_total={0} selected={1} queue={2} role_skip={3} freshness_skip={4} blocked={5}".format(
            payload["scope_total_canonical_docs"],
            payload["scope_selected_docs"],
            len(payload["validate_queue"]),
            len(payload["skipped_by_role"]),
            len(payload["skipped_by_freshness"]),
            len(payload["validation_blocked_by_metadata"]),
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
