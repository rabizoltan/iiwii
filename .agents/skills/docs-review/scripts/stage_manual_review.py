#!/usr/bin/env python3
"""
Move manual-review docs into docs/manual_review_needed/ so follow-up cleanup
passes can focus on a smaller working set.
"""

from __future__ import annotations

import argparse
import shutil
from pathlib import Path

from docs_cleaner import MANUAL, classify_file, extract_canonical_keep_set


def stage_manual_review(
    docs_root: Path,
    manual_review_root: Path,
    archive_root: Path,
    apply: bool,
) -> list[tuple[Path, Path]]:
    canonical_keep = extract_canonical_keep_set(docs_root)
    candidates: list[tuple[Path, Path]] = []

    for source in sorted(docs_root.rglob("*.md")):
        if archive_root in source.parents:
            continue
        if manual_review_root in source.parents:
            continue

        result = classify_file(source, docs_root, canonical_keep)
        if result.bucket != MANUAL:
            continue

        rel = source.relative_to(docs_root)
        rel_lower = str(rel).replace("/", "\\").lower()
        if rel_lower in canonical_keep:
            continue

        destination = manual_review_root / rel
        candidates.append((source, destination))

    for source, destination in candidates:
        print(f"{'[APPLY]' if apply else '[DRY-RUN]'} {source} -> {destination}")
        if not apply:
            continue

        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(source), str(destination))

    return candidates


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--docs-root", default="docs", help="Path to docs root")
    parser.add_argument(
        "--manual-review-root",
        default="docs/manual_review_needed",
        help="Path to the manual-review staging root",
    )
    parser.add_argument("--archive-root", default="docs/archive", help="Path to archive root")
    parser.add_argument("--apply", action="store_true", help="Actually move files")
    args = parser.parse_args()

    docs_root = Path(args.docs_root)
    manual_review_root = Path(args.manual_review_root)
    archive_root = Path(args.archive_root)

    if not docs_root.exists():
        raise SystemExit(f"Docs root not found: {docs_root}")

    candidates = stage_manual_review(
        docs_root,
        manual_review_root=manual_review_root,
        archive_root=archive_root,
        apply=args.apply,
    )
    print(f"manual_review_candidates={len(candidates)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
