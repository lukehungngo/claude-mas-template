---
description: Audit MAS usage across local Claude Code sessions — find versions, agent/skill dispatch patterns, outdated usage
---

# MAS Audit

Audit MAS (Multi-Agent System) usage across all local Claude Code sessions.

Arguments: $ARGUMENTS

## What This Does

Scans `~/.claude/projects/` session logs to:
1. Find all sessions that used MAS agents or skills
2. Detect which MAS version (v1.x bare names vs v2.0+ namespaced `mas:*:*`)
3. Count agent dispatches and skill invocations per session
4. Cross-check against the latest MAS template version (from git tags)
5. Flag outdated sessions still using v1.x conventions

## Run

```bash
python3 .claude/scripts/mas-audit.py
```

### Options

| Flag | Effect |
|------|--------|
| (none) | Show only sessions with MAS usage |
| `--verbose` or `-v` | Show ALL sessions including non-MAS ones |
| `--json` | Output machine-readable JSON |

## Interpreting Results

- **v2.0+ (namespaced agents)** — Current. Uses `mas:engineer:engineer` style dispatch.
- **v1.x (bare agent names)** — Outdated. Uses `engineer`, `reviewer` style dispatch. Should migrate to v2.0+.
- **none** — Session didn't use MAS agents or skills (normal for non-MAS projects).

## Quick Run

If the user just says `/audit` with no arguments, run the script and present the report.
If the user says `/audit --verbose`, include non-MAS sessions.
If the user says `/audit --json`, output JSON for further processing.

Execute the audit now:

```bash
python3 .claude/scripts/mas-audit.py $ARGUMENTS
```
