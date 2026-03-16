#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
from pathlib import Path

SECTIONS = ["Todo", "In Progress", "Done"]
HEADER_RE = re.compile(r"^##\s+(?P<name>.+?)\s*$")
ITEM_RE = re.compile(r"^\s*-\s*(?:\[[ xX]\]\s*)?(?P<text>.+?)\s*$")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Move task item(s) between Todo/In Progress/Done.")
    parser.add_argument("--task-file", required=True)
    parser.add_argument("--from", dest="from_section", required=True, choices=SECTIONS)
    parser.add_argument("--to", dest="to_section", required=True, choices=SECTIONS)
    parser.add_argument("--item", action="append", required=True, help="Exact item text (without checkbox prefix).")
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


def normalize_item_text(line: str) -> str | None:
    m = ITEM_RE.match(line.rstrip("\n"))
    if not m:
        return None
    text = m.group("text").strip()
    if text == "(none)":
        return None
    return text


def section_item_line_indexes(lines: list[str], section: str) -> list[int]:
    start, end = find_section_bounds(lines, section)
    indexes: list[int] = []
    for i in range(start + 1, end):
        if normalize_item_text(lines[i]) is not None:
            indexes.append(i)
    return indexes


def first_insert_index(lines: list[str], section: str) -> int:
    start, end = find_section_bounds(lines, section)
    return end if end > start else start + 1


def remove_none_placeholder(lines: list[str], section: str) -> None:
    start, end = find_section_bounds(lines, section)
    for i in range(start + 1, end):
        if lines[i].strip() == "- (none)":
            lines.pop(i)
            return


def ensure_none_placeholder(lines: list[str], section: str) -> None:
    start, end = find_section_bounds(lines, section)
    has_items = any(normalize_item_text(lines[i]) is not None for i in range(start + 1, end))
    has_none = any(lines[i].strip() == "- (none)" for i in range(start + 1, end))
    if not has_items and not has_none:
        insert_at = start + 1
        lines.insert(insert_at, "- (none)\n")


def checkbox_line(text: str, section: str) -> str:
    checked = section == "Done"
    mark = "x" if checked else " "
    return f"- [{mark}] {text}\n"


def main() -> int:
    args = parse_args()
    if args.from_section == args.to_section:
        raise SystemExit("Source and target sections are identical.")

    task_file = Path(args.task_file)
    lines = task_file.read_text(encoding="utf-8").splitlines(keepends=True)

    wanted = {item.strip() for item in args.item if item.strip()}
    if not wanted:
        raise SystemExit("No valid --item values provided.")

    source_indexes = section_item_line_indexes(lines, args.from_section)
    found_map: dict[str, int] = {}
    for idx in source_indexes:
        text = normalize_item_text(lines[idx])
        if text in wanted and text not in found_map:
            found_map[text] = idx

    missing = [item for item in wanted if item not in found_map]
    if missing:
        raise SystemExit(f"Items not found in section '{args.from_section}': {missing}")

    # Remove from source bottom-up to keep indexes stable.
    removed_items = sorted(found_map.items(), key=lambda kv: kv[1], reverse=True)
    moved_texts: list[str] = []
    for text, idx in removed_items:
        lines.pop(idx)
        moved_texts.append(text)

    # Insert into target at section end.
    remove_none_placeholder(lines, args.to_section)
    insert_at = first_insert_index(lines, args.to_section)
    for text in sorted(moved_texts):
        lines.insert(insert_at, checkbox_line(text, args.to_section))
        insert_at += 1

    ensure_none_placeholder(lines, args.from_section)
    ensure_none_placeholder(lines, args.to_section)

    task_file.write_text("".join(lines), encoding="utf-8")
    print(f"Updated: {task_file}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

