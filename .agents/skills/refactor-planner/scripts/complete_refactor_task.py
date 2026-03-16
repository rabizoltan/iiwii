#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import shutil
from pathlib import Path

SECTIONS = ["Todo", "In Progress", "Done"]
HEADER_RE = re.compile(r"^##\s+(?P<name>.+?)\s*$")
ITEM_RE = re.compile(r"^\s*-\s*(?:\[[ xX]\]\s*)?(?P<text>.+?)\s*$")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Complete and archive a refactor task if no open items remain.")
    parser.add_argument("--task-file", required=True)
    parser.add_argument("--archive-dir", default="docs/archive")
    parser.add_argument("--project-root", default=".")
    parser.add_argument("--overwrite", action="store_true")
    return parser.parse_args()


def find_section_bounds(lines: list[str], section: str) -> tuple[int, int]:
    start = -1
    end = len(lines)
    for idx, line in enumerate(lines):
        m = HEADER_RE.match(line.rstrip("\n"))
        if not m:
            continue
        name = m.group("name")
        if name == section:
            start = idx
            continue
        if start >= 0 and name in SECTIONS:
            end = idx
            break
    if start < 0:
        raise ValueError(f"Section not found: {section}")
    return start, end


def unresolved_items(lines: list[str], section: str) -> list[str]:
    start, end = find_section_bounds(lines, section)
    unresolved: list[str] = []
    for i in range(start + 1, end):
        m = ITEM_RE.match(lines[i].rstrip("\n"))
        if not m:
            continue
        text = m.group("text").strip()
        if text and text != "(none)":
            unresolved.append(text)
    return unresolved


def mark_completed_status(lines: list[str]) -> list[str]:
    out = list(lines)
    for i, line in enumerate(out):
        if line.startswith("Status:"):
            out[i] = "Status: completed\n"
            return out
    if out and out[0].startswith("# "):
        out.insert(1, "\n")
        out.insert(2, "Status: completed\n")
    else:
        out.insert(0, "Status: completed\n")
    return out


def main() -> int:
    args = parse_args()
    task_file = Path(args.task_file).resolve()
    project_root = Path(args.project_root).resolve()
    archive_dir = (project_root / args.archive_dir).resolve()
    archive_dir.mkdir(parents=True, exist_ok=True)

    lines = task_file.read_text(encoding="utf-8").splitlines(keepends=True)
    todo_open = unresolved_items(lines, "Todo")
    in_progress_open = unresolved_items(lines, "In Progress")
    if todo_open or in_progress_open:
        raise SystemExit(
            "Task is not complete. Open items remain.\n"
            f"Todo: {todo_open}\n"
            f"In Progress: {in_progress_open}"
        )

    updated = mark_completed_status(lines)
    task_file.write_text("".join(updated), encoding="utf-8")

    target = archive_dir / task_file.name
    if target.exists() and not args.overwrite:
        raise SystemExit(f"Archive target already exists: {target}")
    if target.exists() and args.overwrite:
        target.unlink()

    shutil.move(str(task_file), str(target))
    print(str(target))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
