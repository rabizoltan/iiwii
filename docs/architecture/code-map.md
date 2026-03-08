# Code Map

## Purpose
- Track the actual runtime file relationships once code exists.
- Give humans and LLMs one place to see which files own behavior and which files depend on them.

## Usage Rules
- Update this file when a new runtime file is created.
- Update this file when ownership or important references change.
- Keep entries factual and short.
- Do not duplicate full design logic here; point back to source-of-truth docs.

## Current State
- No gameplay code exists in this repository yet.

## Entry Format
Use one row per important runtime file or scene once implementation starts.

| Path | Type | Owns | Referenced By | Primary Docs |
| --- | --- | --- | --- | --- |
| _example_ | script/scene/resource | short responsibility | important inbound references | relevant doc links |

## First Expected Entries
When the first playable slice starts, add entries for:
- main scene
- player actor root
- enemy actor root
- enemy navigation logic
- attack/projectile logic
- any shared tuning resource or config file
