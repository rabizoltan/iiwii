#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Update Last validated (and optional Last updated) fields.")
    parser.add_argument("--file", action="append", required=True, help="Target markdown file. Repeatable.")
    parser.add_argument("--date", default=dt.date.today().isoformat())
    parser.add_argument("--set-updated", action="store_true")
    parser.add_argument("--apply", action="store_true")
    return parser.parse_args()


def upsert(lines: list[str], key: str, value: str) -> tuple[list[str], bool]:
    prefix = f"{key}:"
    for i, line in enumerate(lines):
        if line.startswith(prefix):
            new_line = f"{prefix} {value}\n"
            if lines[i] != new_line:
                lines[i] = new_line
                return lines, True
            return lines, False
    insert_at = 1 if lines and lines[0].startswith("# ") else 0
    lines.insert(insert_at, f"{prefix} {value}\n")
    return lines, True


def main() -> int:
    args = parse_args()
    changed = 0

    for raw in args.file:
        path = Path(raw)
        lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
        file_changed = False

        lines, c1 = upsert(lines, "Last validated", args.date)
        file_changed = file_changed or c1
        if args.set_updated:
            lines, c2 = upsert(lines, "Last updated", args.date)
            file_changed = file_changed or c2

        if file_changed and args.apply:
            path.write_text("".join(lines), encoding="utf-8")
        if file_changed:
            changed += 1
        print(f"{'[APPLY]' if args.apply else '[DRY-RUN]'} {path} changed={file_changed}")

    print(f"files_changed={changed}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

