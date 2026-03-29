#!/usr/bin/env python3
"""
MAS Audit — Scan local Claude Code sessions to find MAS usage patterns.

Reads ~/.claude/projects/*//*.jsonl session logs and reports:
- Which projects use MAS agents/skills
- Which MAS version (agent naming convention) each session uses
- Agent dispatch counts and skill invocation counts
- Comparison against the latest MAS template version
"""

import json
import os
import glob
import sys
from collections import defaultdict
from datetime import datetime
from pathlib import Path

CLAUDE_DIR = Path.home() / ".claude"
PROJECTS_DIR = CLAUDE_DIR / "projects"
# MAS template canonical location
MAS_TEMPLATE_DIR = None  # auto-detected


def detect_mas_version(agents_used, skills_used):
    """Infer MAS version from agent naming conventions."""
    # v2.0+ uses namespaced agents: mas:engineer:engineer
    namespaced = [a for a in agents_used if a.startswith("mas:")]
    # v1.x uses bare names: engineer, reviewer, researcher
    bare_mas = [a for a in agents_used if a in (
        "engineer", "reviewer", "researcher", "differential-reviewer",
        "bug-fixer", "orchestrator", "ui-ux-designer"
    )]
    # Skills with mas: prefix = v2.0+
    namespaced_skills = [s for s in skills_used if s.startswith("mas:")]
    bare_skills = [s for s in skills_used if s in (
        "writing-plans", "verification", "finishing-branch",
        "test-driven-development", "systematic-debugging",
        "se-principles", "reliability-review", "property-based-testing",
        "differential-review", "ask-questions", "requesting-code-review",
        "receiving-code-review", "executing-plans",
        "subagent-driven-development"
    )]

    if namespaced:
        return "v2.0+", "namespaced agents (mas:*:*)"
    elif bare_mas:
        return "v1.x", "bare agent names"
    elif namespaced_skills:
        return "v2.0+", "namespaced skills (mas:*)"
    elif bare_skills:
        return "v1.x (skills only)", "bare skill names"
    else:
        return "none", "no MAS usage detected"


def scan_session(jsonl_path):
    """Extract MAS-relevant data from a session JSONL."""
    session_id = os.path.basename(jsonl_path).replace(".jsonl", "")
    result = {
        "session_id": session_id,
        "version": None,
        "cwd": None,
        "msg_count": 0,
        "agents": defaultdict(int),
        "skills": defaultdict(int),
        "first_ts": None,
        "last_ts": None,
    }

    with open(jsonl_path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                data = json.loads(line)
            except (json.JSONDecodeError, ValueError):
                continue

            ts = data.get("timestamp")
            if isinstance(ts, (int, float)):
                if result["first_ts"] is None:
                    result["first_ts"] = ts
                result["last_ts"] = ts

            v = data.get("version")
            if v:
                result["version"] = v
            c = data.get("cwd")
            if c and not result["cwd"]:
                result["cwd"] = c

            if data.get("type") in ("user", "assistant"):
                result["msg_count"] += 1

            # Extract tool_use from message content
            msg = data.get("message", {})
            content = msg.get("content", "")
            items = []
            if isinstance(content, dict):
                items = [content]
            elif isinstance(content, list):
                items = [i for i in content if isinstance(i, dict)]

            for item in items:
                name = item.get("name", "")
                inp = item.get("input", {})
                if name == "Agent":
                    agent_type = inp.get("subagent_type", "general")
                    result["agents"][agent_type] += 1
                elif name == "Skill":
                    skill_name = inp.get("skill", "?")
                    result["skills"][skill_name] += 1

    return result


def get_latest_mas_version():
    """Get the latest MAS template version from git tags."""
    import subprocess
    for candidate in [
        Path.home() / "working" / "ai" / "claude-mas-template",
        Path.cwd(),
    ]:
        if (candidate / ".git").exists() and (candidate / "agents").exists():
            try:
                tags = subprocess.check_output(
                    ["git", "tag", "-l", "v*"],
                    cwd=str(candidate),
                    stderr=subprocess.DEVNULL,
                ).decode().strip().split("\n")
                if tags and tags[0]:
                    return sorted(tags)[-1], str(candidate)
            except subprocess.CalledProcessError:
                pass
    return "unknown", None


def format_ts(ts):
    if ts is None:
        return "?"
    try:
        return datetime.fromtimestamp(ts / 1000).strftime("%Y-%m-%d %H:%M")
    except (OSError, ValueError):
        return "?"


def main():
    verbose = "--verbose" in sys.argv or "-v" in sys.argv
    json_output = "--json" in sys.argv

    if not PROJECTS_DIR.exists():
        print("No Claude Code projects found at ~/.claude/projects/")
        sys.exit(1)

    latest_version, mas_path = get_latest_mas_version()

    # Scan all sessions
    projects = defaultdict(list)
    for proj_dir in sorted(PROJECTS_DIR.iterdir()):
        if not proj_dir.is_dir():
            continue
        proj_name = proj_dir.name
        for jsonl in sorted(proj_dir.glob("*.jsonl")):
            session = scan_session(str(jsonl))
            projects[proj_name].append(session)

    if json_output:
        output = {
            "latest_mas_version": latest_version,
            "mas_template_path": mas_path,
            "scan_time": datetime.now().isoformat(),
            "projects": {},
        }
        for proj_name, sessions in projects.items():
            output["projects"][proj_name] = []
            for s in sessions:
                mas_ver, reason = detect_mas_version(
                    list(s["agents"].keys()), list(s["skills"].keys())
                )
                output["projects"][proj_name].append({
                    "session_id": s["session_id"],
                    "claude_version": s["version"],
                    "mas_version": mas_ver,
                    "mas_detection_reason": reason,
                    "cwd": s["cwd"],
                    "messages": s["msg_count"],
                    "period": f'{format_ts(s["first_ts"])} -> {format_ts(s["last_ts"])}',
                    "agents": dict(s["agents"]),
                    "skills": dict(s["skills"]),
                })
        print(json.dumps(output, indent=2))
        return

    # --- Text report ---
    print("=" * 70)
    print("MAS AUDIT REPORT")
    print(f"Scanned: {datetime.now().strftime('%Y-%m-%d %H:%M')}")
    print(f"Latest MAS template version: {latest_version}")
    if mas_path:
        print(f"Template path: {mas_path}")
    print("=" * 70)

    total_sessions = 0
    mas_sessions = 0
    version_counts = defaultdict(int)

    for proj_name, sessions in projects.items():
        # Derive readable project name from encoded path
        readable = proj_name.replace("-Users-soh-", "~/").replace("-", "/")

        has_mas = any(
            detect_mas_version(list(s["agents"].keys()), list(s["skills"].keys()))[0] != "none"
            for s in sessions
        )

        if not has_mas and not verbose:
            total_sessions += len(sessions)
            continue

        print(f"\n{'─' * 70}")
        print(f"PROJECT: {readable}")
        print(f"Sessions: {len(sessions)}")
        total_sessions += len(sessions)

        for s in sessions:
            mas_ver, reason = detect_mas_version(
                list(s["agents"].keys()), list(s["skills"].keys())
            )
            version_counts[mas_ver] += 1

            if mas_ver == "none" and not verbose:
                continue

            mas_sessions += 1
            sid = s["session_id"][:12]
            period = f'{format_ts(s["first_ts"])} -> {format_ts(s["last_ts"])}'

            print(f"\n  Session {sid}...")
            print(f"    Claude CLI: {s['version'] or '?'}")
            print(f"    MAS version: {mas_ver} ({reason})")
            print(f"    Period: {period}")
            print(f"    Messages: {s['msg_count']}")

            if s["agents"]:
                print(f"    Agents dispatched:")
                for agent, count in sorted(s["agents"].items(), key=lambda x: -x[1]):
                    print(f"      {agent}: {count}x")

            if s["skills"]:
                print(f"    Skills invoked:")
                for skill, count in sorted(s["skills"].items(), key=lambda x: -x[1]):
                    print(f"      {skill}: {count}x")

    # Summary
    print(f"\n{'=' * 70}")
    print("SUMMARY")
    print(f"{'=' * 70}")
    print(f"Total sessions scanned: {total_sessions}")
    print(f"Sessions using MAS: {mas_sessions}")
    print(f"\nMAS version distribution:")
    for ver, count in sorted(version_counts.items()):
        marker = ""
        if ver == "v2.0+" and latest_version.startswith("v2"):
            marker = " (current)"
        elif ver == "v1.x":
            marker = " (outdated)"
        print(f"  {ver}: {count} sessions{marker}")

    # Cross-check: are any projects using old-style agents?
    outdated = []
    for proj_name, sessions in projects.items():
        for s in sessions:
            mas_ver, _ = detect_mas_version(
                list(s["agents"].keys()), list(s["skills"].keys())
            )
            if mas_ver == "v1.x":
                readable = proj_name.replace("-Users-soh-", "~/").replace("-", "/")
                outdated.append((readable, s["session_id"][:12]))

    if outdated:
        print(f"\nOUTDATED SESSIONS (using v1.x naming):")
        for proj, sid in outdated:
            print(f"  {proj} / {sid}...")
        print(f"\nAction: These projects should update to v2.0+ namespaced agents (mas:*:*)")

    print()


if __name__ == "__main__":
    main()
