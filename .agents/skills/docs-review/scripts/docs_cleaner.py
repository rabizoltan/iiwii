#!/usr/bin/env python3
"""
Classify markdown files under docs/ into keep / archive_candidate / manual_review,
while also evaluating whether they live in the correct docs layer.
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from pathlib import Path


KEEP = "keep"
ARCHIVE = "archive_candidate"
MANUAL = "manual_review"

LAYER_CANONICAL = "canonical_top_level"
LAYER_CANONICAL_SECTION = "canonical_section"
LAYER_ARCHIVE = "archive"
LAYER_MANUAL_REVIEW = "manual_review_needed"
LAYER_REFERENCE = "reference_subfolder"
LAYER_IDEAS = "ideas_subfolder"
LAYER_OTHER = "other_subfolder"


STRONG_KEEP_NAME_PATTERNS = [
    re.compile(r"^README\.md$", re.IGNORECASE),
    re.compile(r"^feature-matrix\.md$", re.IGNORECASE),
    re.compile(r"^high-level-architecture\.md$", re.IGNORECASE),
    re.compile(r"^code-map\.md$", re.IGNORECASE),
    re.compile(r"^combat\.md$", re.IGNORECASE),
    re.compile(r"^movement-spec\.md$", re.IGNORECASE),
    re.compile(r"^player-hero-progression\.md$", re.IGNORECASE),
    re.compile(r"^networking\.md$", re.IGNORECASE),
]

ARCHIVE_NAME_PATTERNS = [
    re.compile(r"todo", re.IGNORECASE),
    re.compile(r"handover", re.IGNORECASE),
    re.compile(r"session", re.IGNORECASE),
    re.compile(r"refactor", re.IGNORECASE),
]

MANUAL_NAME_PATTERNS = [
    re.compile(r"spec", re.IGNORECASE),
    re.compile(r"status", re.IGNORECASE),
    re.compile(r"notes", re.IGNORECASE),
    re.compile(r"guide", re.IGNORECASE),
    re.compile(r"example", re.IGNORECASE),
]

KEEP_CONTENT_PATTERNS = [
    re.compile(r"\b(runtime invariants|gameplay documentation|feature matrix|balance baseline)\b", re.IGNORECASE),
    re.compile(r"\b(current runtime|must stay stable|source:|sources:)\b", re.IGNORECASE),
    re.compile(r"\b(active sanitation runtime reference|active visual system draft|product-facing design audit|active / current)\b", re.IGNORECASE),
]

FORWARD_NOTE_PATTERNS = [
    re.compile(r"\bactive forward note\b", re.IGNORECASE),
    re.compile(r"\bactive forward plan\b", re.IGNORECASE),
]

ARCHIVE_CONTENT_PATTERNS = [
    re.compile(r"\b(execution plan|implementation plan|session handover|brainstorm|temporary|task breakdown)\b", re.IGNORECASE),
    re.compile(r"\b(next steps|remaining work|follow-up work|checklist for later)\b", re.IGNORECASE),
]

MANUAL_CONTENT_PATTERNS = [
    re.compile(r"\b(status|current gaps|known gaps|design)\b", re.IGNORECASE),
    re.compile(r"\b(planned|implemented|partial)\b", re.IGNORECASE),
]

TOPIC_PATTERNS: dict[str, list[re.Pattern[str]]] = {
    "rendering": [
        re.compile(r"\brender", re.IGNORECASE),
        re.compile(r"\brenderer", re.IGNORECASE),
        re.compile(r"\bvisual", re.IGNORECASE),
        re.compile(r"\bgraphics", re.IGNORECASE),
        re.compile(r"\bworld fx\b", re.IGNORECASE),
        re.compile(r"\bworld-fx\b", re.IGNORECASE),
        re.compile(r"\bfx\b", re.IGNORECASE),
        re.compile(r"\bterrain coloring\b", re.IGNORECASE),
        re.compile(r"\bterrain-coloring\b", re.IGNORECASE),
        re.compile(r"\bwater rendering\b", re.IGNORECASE),
        re.compile(r"\bwater-rendering\b", re.IGNORECASE),
        re.compile(r"\boverlay\b", re.IGNORECASE),
        re.compile(r"\bpost[- ]?process", re.IGNORECASE),
    ],
    "materials_textures": [
        re.compile(r"\bmaterial", re.IGNORECASE),
        re.compile(r"\btexture", re.IGNORECASE),
        re.compile(r"\bshader", re.IGNORECASE),
        re.compile(r"\basset pipeline\b", re.IGNORECASE),
        re.compile(r"\bterrain coloring\b", re.IGNORECASE),
        re.compile(r"\bterrain-coloring\b", re.IGNORECASE),
        re.compile(r"\bblender\b", re.IGNORECASE),
    ],
    "map_generation": [
        re.compile(r"\bmapgen\b", re.IGNORECASE),
        re.compile(r"\bmap generation\b", re.IGNORECASE),
        re.compile(r"\bgenerator\b", re.IGNORECASE),
        re.compile(r"\bseed(ed)?\b", re.IGNORECASE),
        re.compile(r"\bbiome\b", re.IGNORECASE),
        re.compile(r"\bterrain\b", re.IGNORECASE),
        re.compile(r"\briver\b", re.IGNORECASE),
        re.compile(r"\blake\b", re.IGNORECASE),
        re.compile(r"\bshore\b", re.IGNORECASE),
        re.compile(r"\bheight(field)?\b", re.IGNORECASE),
        re.compile(r"\bmeander\b", re.IGNORECASE),
        re.compile(r"\bterrain coloring\b", re.IGNORECASE),
        re.compile(r"\bterrain-coloring\b", re.IGNORECASE),
    ],
    "engine_runtime": [
        re.compile(r"\bengine\b", re.IGNORECASE),
        re.compile(r"\bgodot\b", re.IGNORECASE),
        re.compile(r"\bbootstrap\b", re.IGNORECASE),
        re.compile(r"\borchestration\b", re.IGNORECASE),
        re.compile(r"\bruntime loop\b", re.IGNORECASE),
        re.compile(r"\binput\b", re.IGNORECASE),
    ],
    "gameplay_simulation": [
        re.compile(r"\bgameplay\b", re.IGNORECASE),
        re.compile(r"\bsimulation\b", re.IGNORECASE),
        re.compile(r"\bgame logic(s)?\b", re.IGNORECASE),
        re.compile(r"\bworker\b", re.IGNORECASE),
        re.compile(r"\bjob\b", re.IGNORECASE),
        re.compile(r"\bprofession\b", re.IGNORECASE),
        re.compile(r"\bcitizen\b", re.IGNORECASE),
        re.compile(r"\bhousehold\b", re.IGNORECASE),
        re.compile(r"\bsanitation\b", re.IGNORECASE),
        re.compile(r"\bwaste\b", re.IGNORECASE),
        re.compile(r"\blatrine\b", re.IGNORECASE),
        re.compile(r"\beconomy\b", re.IGNORECASE),
        re.compile(r"\bbalance\b", re.IGNORECASE),
    ],
    "systems_flows": [
        re.compile(r"\bsystem\b", re.IGNORECASE),
        re.compile(r"\bflow\b", re.IGNORECASE),
        re.compile(r"\bpipeline\b", re.IGNORECASE),
        re.compile(r"\bchain\b", re.IGNORECASE),
        re.compile(r"\bitem\b", re.IGNORECASE),
        re.compile(r"\bimplementation\b", re.IGNORECASE),
        re.compile(r"\bguide\b", re.IGNORECASE),
        re.compile(r"\brecipe\b", re.IGNORECASE),
        re.compile(r"\btoolchain\b", re.IGNORECASE),
    ],
    "pathfinding_logistics": [
        re.compile(r"\bpathfinding\b", re.IGNORECASE),
        re.compile(r"\bpathing\b", re.IGNORECASE),
        re.compile(r"\blogistics\b", re.IGNORECASE),
        re.compile(r"\bhaul\b", re.IGNORECASE),
        re.compile(r"\bdeliver\b", re.IGNORECASE),
        re.compile(r"\breservation\b", re.IGNORECASE),
        re.compile(r"\brouting\b", re.IGNORECASE),
    ],
    "ui_ux": [
        re.compile(r"\bui\b", re.IGNORECASE),
        re.compile(r"\buser interface\b", re.IGNORECASE),
        re.compile(r"\bhud\b", re.IGNORECASE),
        re.compile(r"\bpanel\b", re.IGNORECASE),
        re.compile(r"\bmenu\b", re.IGNORECASE),
        re.compile(r"\bux\b", re.IGNORECASE),
        re.compile(r"\bbrand\b", re.IGNORECASE),
        re.compile(r"\bstyle\b", re.IGNORECASE),
        re.compile(r"\bstyle system\b", re.IGNORECASE),
        re.compile(r"\bdesign pattern\b", re.IGNORECASE),
        re.compile(r"\bdesign\b", re.IGNORECASE),
        re.compile(r"\binteraction\b", re.IGNORECASE),
        re.compile(r"\bui guide\b", re.IGNORECASE),
        re.compile(r"\bui audit\b", re.IGNORECASE),
    ],
    "performance": [
        re.compile(r"\bperformance\b", re.IGNORECASE),
        re.compile(r"\bperformance guide\b", re.IGNORECASE),
        re.compile(r"\btuning\b", re.IGNORECASE),
        re.compile(r"\boptimization\b", re.IGNORECASE),
        re.compile(r"\bframe(-| )time\b", re.IGNORECASE),
        re.compile(r"\bspike\b", re.IGNORECASE),
        re.compile(r"\bbudget\b", re.IGNORECASE),
        re.compile(r"\bculling\b", re.IGNORECASE),
        re.compile(r"\bprofil", re.IGNORECASE),
    ],
    "animation": [
        re.compile(r"\banimation\b", re.IGNORECASE),
        re.compile(r"\brig\b", re.IGNORECASE),
        re.compile(r"\bskeleton\b", re.IGNORECASE),
    ],
    "save_persistence": [
        re.compile(r"\bsave\b", re.IGNORECASE),
        re.compile(r"\bload\b", re.IGNORECASE),
        re.compile(r"\bpersist", re.IGNORECASE),
        re.compile(r"\bschema\b", re.IGNORECASE),
        re.compile(r"\bdeterminism\b", re.IGNORECASE),
        re.compile(r"\bsignature\b", re.IGNORECASE),
        re.compile(r"\bflood\b", re.IGNORECASE),
    ],
    "testing_ops": [
        re.compile(r"\bsmoke\b", re.IGNORECASE),
        re.compile(r"\btest\b", re.IGNORECASE),
        re.compile(r"\bvalidation\b", re.IGNORECASE),
        re.compile(r"\bdiagnostic\b", re.IGNORECASE),
        re.compile(r"\blog\b", re.IGNORECASE),
        re.compile(r"\bcsv\b", re.IGNORECASE),
        re.compile(r"\brunbook\b", re.IGNORECASE),
    ],
    "tooling_agents": [
        re.compile(r"\bllm\b", re.IGNORECASE),
        re.compile(r"\bagent\b", re.IGNORECASE),
        re.compile(r"\bskill\b", re.IGNORECASE),
        re.compile(r"\bworkflow\b", re.IGNORECASE),
    ],
}

DOC_ROLE_PATTERNS: dict[str, list[re.Pattern[str]]] = {
    "system": [
        re.compile(r"\bsystem\b", re.IGNORECASE),
        re.compile(r"\bflow\b", re.IGNORECASE),
        re.compile(r"\bpipeline\b", re.IGNORECASE),
    ],
    "implementation_guide": [
        re.compile(r"\bimplementation guide\b", re.IGNORECASE),
        re.compile(r"\bimplementation\b", re.IGNORECASE),
    ],
    "performance_guide": [
        re.compile(r"\bperformance guide\b", re.IGNORECASE),
        re.compile(r"\bperformance tuning\b", re.IGNORECASE),
    ],
    "ui_guide": [
        re.compile(r"\bui guide\b", re.IGNORECASE),
        re.compile(r"\bux guide\b", re.IGNORECASE),
        re.compile(r"\buser interface guide\b", re.IGNORECASE),
    ],
    "guide": [
        re.compile(r"\bguide\b", re.IGNORECASE),
        re.compile(r"\bimplementation guide\b", re.IGNORECASE),
        re.compile(r"\bhow to\b", re.IGNORECASE),
    ],
    "style_system": [
        re.compile(r"\bstyle system\b", re.IGNORECASE),
        re.compile(r"\bstyle guide\b", re.IGNORECASE),
        re.compile(r"\bui style\b", re.IGNORECASE),
        re.compile(r"\bbrand style\b", re.IGNORECASE),
    ],
    "pattern": [
        re.compile(r"\bstyle\b", re.IGNORECASE),
        re.compile(r"\bdesign system\b", re.IGNORECASE),
        re.compile(r"\bdesign pattern\b", re.IGNORECASE),
        re.compile(r"\bpattern\b", re.IGNORECASE),
    ],
    "matrix": [
        re.compile(r"\bmatrix\b", re.IGNORECASE),
    ],
    "baseline": [
        re.compile(r"\bbaseline\b", re.IGNORECASE),
        re.compile(r"\binvariants?\b", re.IGNORECASE),
    ],
    "status": [
        re.compile(r"\bstatus\b", re.IGNORECASE),
    ],
    "summary": [
        re.compile(r"\bsummary\b", re.IGNORECASE),
        re.compile(r"\bsnapshot\b", re.IGNORECASE),
    ],
    "polish": [
        re.compile(r"\bpolish\b", re.IGNORECASE),
    ],
    "variants": [
        re.compile(r"\bvariants?\b", re.IGNORECASE),
    ],
    "plan": [
        re.compile(r"\bplan\b", re.IGNORECASE),
        re.compile(r"\broadmap\b", re.IGNORECASE),
    ],
    "backlog": [
        re.compile(r"\bbacklog\b", re.IGNORECASE),
        re.compile(r"\btodo\b", re.IGNORECASE),
        re.compile(r"\bbugs?\b", re.IGNORECASE),
    ],
    "audit": [
        re.compile(r"\baudit\b", re.IGNORECASE),
    ],
    "runbook": [
        re.compile(r"\brunbook\b", re.IGNORECASE),
    ],
    "spec": [
        re.compile(r"\bspec\b", re.IGNORECASE),
    ],
}

ROLE_PRIORITY = {
    "system": 6,
    "implementation_guide": 6,
    "performance_guide": 6,
    "ui_guide": 6,
    "guide": 5,
    "style_system": 5,
    "pattern": 5,
    "matrix": 5,
    "baseline": 5,
    "runbook": 4,
    "audit": 3,
    "spec": 3,
    "status": 1,
    "summary": 1,
    "polish": 1,
    "variants": 1,
    "plan": 1,
    "backlog": 0,
}

SUBORDINATE_ROLES = {"status", "summary", "polish", "variants"}


@dataclass
class FileProfile:
    path: Path
    rel_text: str
    rel_lower: str
    name: str
    text: str | None
    layer: str
    is_archive_like_folder: bool
    is_manual_review_folder: bool
    is_top_level: bool
    is_ideas_folder: bool
    is_reference_folder: bool
    is_canonical_keep: bool
    is_active_forward_note: bool
    topics: set[str]
    roles: set[str]


@dataclass
class Classification:
    path: str
    bucket: str
    reason: str
    signals: list[str]
    layer: str
    location_note: str | None


def extract_canonical_keep_set(docs_root: Path) -> set[str]:
    keep: set[str] = set()
    readmes = [docs_root / "README.md"] + sorted(docs_root.glob("**/README.md"))
    for readme in readmes:
        if not readme.exists():
            continue
        text = readme.read_text(encoding="utf-8")
        for match in re.finditer(r"\(([^)]+\.md)\)", text):
            raw_target = match.group(1).strip()
            candidate = Path(raw_target)
            normalized: Path | None = None
            if candidate.is_absolute():
                try:
                    normalized = candidate.resolve().relative_to(docs_root.resolve())
                except Exception:
                    normalized = None
            else:
                resolved = (readme.parent / candidate).resolve()
                try:
                    normalized = resolved.relative_to(docs_root.resolve())
                except Exception:
                    normalized = None
            if normalized is not None:
                keep.add(str(normalized).replace("/", "\\").lower())
    keep.add("readme.md")
    return keep


def infer_labels(name: str, text: str | None, patterns: dict[str, list[re.Pattern[str]]]) -> set[str]:
    haystack = name if text is None else f"{name}\n{text}"
    labels: set[str] = set()
    for label, label_patterns in patterns.items():
        if any(pattern.search(haystack) for pattern in label_patterns):
            labels.add(label)
    return labels


def build_profiles(docs_root: Path, canonical_keep: set[str]) -> list[FileProfile]:
    profiles: list[FileProfile] = []
    for path in sorted(docs_root.rglob("*.md")):
        rel = path.relative_to(docs_root)
        rel_text = str(rel).replace("/", "\\")
        rel_lower = rel_text.lower()
        rel_parts_lower = [part.lower() for part in rel.parts]

        is_archive_like_folder = any(part in {"old dead end arhive", "archive", "archiv"} for part in rel_parts_lower)
        is_manual_review_folder = "manual_review_needed" in rel_parts_lower
        is_top_level = len(rel.parts) == 1
        is_ideas_folder = "ideas" in rel_parts_lower
        is_reference_folder = "examples" in rel_parts_lower

        if is_archive_like_folder:
            layer = LAYER_ARCHIVE
        elif is_manual_review_folder:
            layer = LAYER_MANUAL_REVIEW
        elif is_top_level:
            layer = LAYER_CANONICAL
        elif rel_parts_lower[0] in {"architecture", "systems", "technical", "vision", "decisions"}:
            layer = LAYER_CANONICAL_SECTION
        elif is_ideas_folder:
            layer = LAYER_IDEAS
        elif is_reference_folder:
            layer = LAYER_REFERENCE
        else:
            layer = LAYER_OTHER

        text = None if is_archive_like_folder else path.read_text(encoding="utf-8")
        profiles.append(
            FileProfile(
                path=path,
                rel_text=rel_text,
                rel_lower=rel_lower,
                name=path.name,
                text=text,
                layer=layer,
                is_archive_like_folder=is_archive_like_folder,
                is_manual_review_folder=is_manual_review_folder,
                is_top_level=is_top_level,
                is_ideas_folder=is_ideas_folder,
                is_reference_folder=is_reference_folder,
                is_canonical_keep=rel_lower in canonical_keep,
                is_active_forward_note=bool(text and any(pattern.search(text) for pattern in FORWARD_NOTE_PATTERNS)),
                topics=infer_labels(path.name, text, TOPIC_PATTERNS),
                roles=infer_labels(path.name, None, DOC_ROLE_PATTERNS),
            )
        )
    return profiles


def best_role_score(roles: set[str]) -> int:
    if not roles:
        return 0
    return max(ROLE_PRIORITY.get(role, 0) for role in roles)


def choose_owner_candidate(profile: FileProfile, profiles: list[FileProfile]) -> FileProfile | None:
    if not profile.topics:
        return None

    best_score = -1
    best_candidate: FileProfile | None = None

    for other in profiles:
        if other.rel_lower == profile.rel_lower:
            continue
        if other.layer not in {LAYER_CANONICAL, LAYER_CANONICAL_SECTION}:
            continue
        if SUBORDINATE_ROLES & other.roles:
            continue

        overlap = profile.topics & other.topics
        if not overlap:
            continue

        score = len(overlap) * 4
        score += best_role_score(other.roles)
        if other.is_canonical_keep:
            score += 3
        if other.is_active_forward_note:
            score -= 2

        if score > best_score:
            best_score = score
            best_candidate = other

    return best_candidate


def classify_file(path: Path, docs_root: Path, canonical_keep: set[str]) -> Classification:
    profiles = build_profiles(docs_root, canonical_keep)
    lookup = {profile.rel_text: profile for profile in profiles}
    profile = lookup[str(path.relative_to(docs_root)).replace("/", "\\")]
    return classify_profile(profile, profiles)


def classify_profile(profile: FileProfile, profiles: list[FileProfile]) -> Classification:
    keep_score = 0
    archive_score = 0
    manual_score = 0
    signals: list[str] = []

    if profile.is_archive_like_folder:
        return Classification(
            path=profile.rel_text,
            bucket=ARCHIVE,
            reason="Already lives in an archive-style folder and should be treated as historical by default.",
            signals=["already_archive_like_folder"],
            layer=profile.layer,
            location_note=None,
        )

    text = profile.text or ""
    owner_candidate = choose_owner_candidate(profile, profiles)
    has_subordinate_role = bool(SUBORDINATE_ROLES & profile.roles)
    is_subordinate_candidate = (
        profile.is_top_level
        and has_subordinate_role
        and not profile.is_active_forward_note
        and owner_candidate is not None
        and best_role_score(owner_candidate.roles) > best_role_score(profile.roles)
    )

    if profile.is_canonical_keep:
        keep_score += 4
        signals.append("canonical_docs_index")

    for pattern in STRONG_KEEP_NAME_PATTERNS:
        if pattern.search(profile.name):
            keep_score += 3
            signals.append(f"keep_name:{pattern.pattern}")

    for pattern in ARCHIVE_NAME_PATTERNS:
        if pattern.search(profile.name):
            archive_score += 2
            signals.append(f"archive_name:{pattern.pattern}")

    for pattern in MANUAL_NAME_PATTERNS:
        if pattern.search(profile.name):
            manual_score += 1
            signals.append(f"manual_name:{pattern.pattern}")

    for pattern in KEEP_CONTENT_PATTERNS:
        if pattern.search(text):
            keep_score += 1
            signals.append(f"keep_content:{pattern.pattern}")

    for pattern in ARCHIVE_CONTENT_PATTERNS:
        if pattern.search(text):
            archive_score += 1
            signals.append(f"archive_content:{pattern.pattern}")

    for pattern in MANUAL_CONTENT_PATTERNS:
        if pattern.search(text):
            manual_score += 1
            signals.append(f"manual_content:{pattern.pattern}")

    if re.search(r"\d{4}-\d{2}-\d{2}", profile.name):
        manual_score += 1
        signals.append("dated_filename")

    if profile.is_manual_review_folder:
        manual_score += 3
        archive_score = max(0, archive_score - 1)
        signals.append("manual_review_layer")

    if profile.is_ideas_folder:
        archive_score = max(0, archive_score - 1)
        manual_score += 1
        signals.append("ideas_layer")

    if profile.is_reference_folder:
        archive_score = max(0, archive_score - 1)
        manual_score += 1
        signals.append("reference_layer")

    if is_subordinate_candidate:
        manual_score += 3
        keep_score = max(0, keep_score - 2)
        signals.append(f"possible_subordinate_to:{owner_candidate.name}")

    location_note: str | None = None

    if is_subordinate_candidate:
        bucket = MANUAL
        reason = f"Looks like a top-level subordinate view ({', '.join(sorted(profile.roles & SUBORDINATE_ROLES))}), and the topic likely belongs under the primary document `{owner_candidate.name}`."
    elif profile.is_top_level and {"summary", "status"} & profile.roles and len(profile.topics) >= 3 and not profile.is_active_forward_note:
        bucket = MANUAL
        reason = "Looks like a top-level summary/status snapshot spanning multiple game-development topics, so it is not a strong canonical document."
    elif profile.is_canonical_keep and (
        archive_score <= 2
        or keep_score >= archive_score
        or profile.is_active_forward_note
    ):
        bucket = KEEP
        reason = "Referenced by the canonical docs index, so it should be kept by default."
    elif profile.is_manual_review_folder:
        bucket = MANUAL
        reason = "Already sits in the manual_review_needed layer, so the next consolidation or manual review pass should work from here."
    elif profile.layer == LAYER_CANONICAL_SECTION and archive_score <= 2:
        bucket = KEEP
        reason = "Lives inside the project's canonical documentation sections, so it should be kept by default."
    elif profile.is_reference_folder and keep_score <= 1:
        bucket = KEEP
        reason = "Looks like external or reference-style material, so it may be kept, but it does not belong to the canonical top-level docs layer."
    elif profile.is_ideas_folder and keep_score <= 1:
        bucket = MANUAL
        reason = "Looks like project-owned but non-canonical idea or parked-plan material."
    elif keep_score >= 4 and archive_score == 0:
        bucket = KEEP
        reason = "Looks like a long-term document due to canonical index coverage or strong reference value."
    elif archive_score >= 3 and keep_score <= 1 and manual_score <= 1:
        bucket = ARCHIVE
        reason = "The file name or content points more toward a temporary plan, audit, handover, or task-history artifact."
    else:
        bucket = MANUAL
        reason = "Signals are mixed, so a manual keep-vs-archive decision is needed."

    if profile.is_top_level and bucket != ARCHIVE:
        if "backlog" in profile.roles and profile.is_active_forward_note:
            location_note = "Looks like an active forward note, so it may stay at top level even if the filename suggests a secondary role."
        elif is_subordinate_candidate and owner_candidate is not None:
            location_note = f"Probably a secondary view or status document related to `{owner_candidate.name}`."
        elif re.search(r"(example)", profile.name, re.IGNORECASE):
            location_note = "Probably external example material; consider moving it under docs/examples."
        elif re.search(r"(otlet|idea|bug-\d+|brainstorm)", profile.name, re.IGNORECASE):
            location_note = "Probably a non-canonical internal note; consider moving it under docs/ideas."
        elif re.search(r"(math|formula|equation|model|hydrology|geology|profile)", profile.name, re.IGNORECASE):
            location_note = "Probably a real-world model or mathematical reference; consider moving it under docs/examples."
        elif re.search(r"(plan)", profile.name, re.IGNORECASE) and not profile.is_canonical_keep:
            location_note = "If this is not an active forward note, consider moving it under docs/ideas or into the archive."

    return Classification(
        path=profile.rel_text,
        bucket=bucket,
        reason=reason,
        signals=signals,
        layer=profile.layer,
        location_note=location_note,
    )


def build_markdown(results: list[Classification], docs_root: Path) -> str:
    groups = {
        KEEP: [],
        ARCHIVE: [],
        MANUAL: [],
    }
    for item in results:
        groups[item.bucket].append(item)

    lines = [
        "# Docs Review Report",
        "",
        f"Reviewed folder: `{docs_root}`",
        "",
        "## keep",
    ]
    if groups[KEEP]:
        for item in groups[KEEP]:
            lines.append(f"- `{item.path}`: {item.reason}")
    else:
        lines.append("- none")

    lines.extend(["", "## archive candidates"])
    if groups[ARCHIVE]:
        for item in groups[ARCHIVE]:
            lines.append(f"- `{item.path}`: {item.reason}")
    else:
        lines.append("- nincs")

    lines.extend(["", "## kezi atnezes kell"])
    if groups[MANUAL]:
        for item in groups[MANUAL]:
            lines.append(f"- `{item.path}`: {item.reason}")
    else:
        lines.append("- nincs")

    location_notes = [item for item in results if item.location_note]
    lines.extend(["", "## reteg-helyessegi megjegyzesek"])
    if location_notes:
        for item in location_notes:
            lines.append(f"- `{item.path}`: {item.location_note}")
    else:
        lines.append("- nincs")

    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--docs-root", default="docs", help="Path to the docs root")
    parser.add_argument(
        "--format",
        default="markdown",
        choices=["markdown", "json"],
        help="Output format",
    )
    args = parser.parse_args()

    docs_root = Path(args.docs_root)
    if not docs_root.exists():
        raise SystemExit(f"Docs root not found: {docs_root}")

    canonical_keep = extract_canonical_keep_set(docs_root)
    profiles = build_profiles(docs_root, canonical_keep)
    results = [classify_profile(profile, profiles) for profile in profiles]

    if args.format == "json":
        payload = [
            {
                "path": item.path,
                "bucket": item.bucket,
                "reason": item.reason,
                "signals": item.signals,
                "layer": item.layer,
                "location_note": item.location_note,
            }
            for item in results
        ]
        print(json.dumps(payload, ensure_ascii=False, indent=2))
        return 0

    print(build_markdown(results, docs_root))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
