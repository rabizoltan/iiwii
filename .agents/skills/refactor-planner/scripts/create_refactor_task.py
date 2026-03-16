#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import re
from pathlib import Path


def slugify(value: str) -> str:
    text = value.strip().lower()
    text = re.sub(r"[^a-z0-9]+", "-", text)
    text = re.sub(r"-{2,}", "-", text).strip("-")
    return text or "refactor-task"


def bulletize(items: list[str], checked: bool = False) -> str:
    if not items:
        return "- (none)"
    prefix = "- [x] " if checked else "- [ ] "
    return "\n".join(f"{prefix}{item.strip()}" for item in items if item.strip())


def listize(items: list[str]) -> str:
    if not items:
        return "- (none)"
    return "\n".join(f"- {item.strip()}" for item in items if item.strip())


def load_template() -> str:
    template_path = Path(__file__).resolve().parent.parent / "assets" / "refactor_task_template.md"
    return template_path.read_text(encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Create a refactor task markdown from a stable template.")
    parser.add_argument("--title", required=True, help="Task title.")
    parser.add_argument("--mode", choices=["Quick", "Deep"], default="Deep")
    parser.add_argument("--goal", default="TBD")
    parser.add_argument("--primary-finding", action="append", default=[])
    parser.add_argument("--secondary-finding", action="append", default=[])
    parser.add_argument("--guardrail", action="append", default=[])
    parser.add_argument("--invariant", action="append", default=[])
    parser.add_argument("--execution-slice", action="append", default=[])
    parser.add_argument("--todo", action="append", default=[])
    parser.add_argument("--in-progress", action="append", default=[])
    parser.add_argument("--done", action="append", default=[])
    parser.add_argument("--project-root", default=".")
    parser.add_argument("--tasks-dir", default="docs/workplans")
    parser.add_argument("--slug", default="")
    parser.add_argument("--overwrite", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    project_root = Path(args.project_root).resolve()
    tasks_dir = (project_root / args.tasks_dir).resolve()
    tasks_dir.mkdir(parents=True, exist_ok=True)

    slug = args.slug.strip() or slugify(args.title)
    out_path = tasks_dir / f"{slug}.md"
    if out_path.exists() and not args.overwrite:
        raise SystemExit(f"Refusing to overwrite existing file: {out_path}")

    today = dt.date.today().isoformat()
    template = load_template()

    primary = args.primary_finding or ["Primary finding TBD"]
    secondary = args.secondary_finding or ["-"]
    guardrails = args.guardrail or ["Current feature behavior must remain unchanged."]
    invariants = args.invariant or ["No runtime ordering regression."]

    if args.mode == "Quick":
        execution = args.execution_slice or [
            "Isolate the smallest safe extraction slice.",
            "Execute one narrow ownership cleanup.",
            "Update docs + feature matrix + close task.",
        ]
        todo_items = args.todo or ["Start with the first narrow slice."]
    else:
        execution = args.execution_slice or [
            "Capture ownership map and scope boundaries.",
            "Execute primary refactor slices incrementally.",
            "Apply secondary cleanup only after primary stability.",
            "Finish with docs update, matrix sync, and archival.",
        ]
        todo_items = args.todo or ["Select first primary slice and mark In Progress."]

    in_progress_items = args.in_progress or []
    done_items = args.done or []

    content = (
        template.replace("{{TITLE}}", args.title.strip())
        .replace("{{TODAY}}", today)
        .replace("{{MODE}}", args.mode)
        .replace("{{GOAL}}", args.goal.strip())
        .replace("{{PRIMARY_FINDINGS}}", listize(primary))
        .replace("{{SECONDARY_FINDINGS}}", listize(secondary))
        .replace("{{GUARDRAILS}}", listize(guardrails))
        .replace("{{INVARIANTS}}", listize(invariants))
        .replace("{{EXECUTION_ORDER}}", listize(execution))
        .replace("{{TODO_ITEMS}}", bulletize(todo_items, checked=False))
        .replace("{{IN_PROGRESS_ITEMS}}", bulletize(in_progress_items, checked=False))
        .replace("{{DONE_ITEMS}}", bulletize(done_items, checked=True))
    )

    out_path.write_text(content, encoding="utf-8")
    print(str(out_path))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
