#!/usr/bin/env python3
"""Install the reviewed, repo-owned defaults without changing selected models."""

import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import shutil
import tomllib

SKILLS = (
    "unslop",
    "frontend-design",
    "agent-browser",
    "herdr",
    "codex-thread-orchestration",
    "thread-closeout",
    "merged",
    "openontology-video",
    "babysit-pr",
    "readme-maintainer",
    "evidence-renderer",
    "repo-quality-guardrails",
    "reliability-scout",
    "automation-audit",
    "issue-grooming",
    "codex-goal-prompting",
    "workos-agent-access",
)
RETIRED = ("design-taste-frontend", "taste-skill", "agent-browser-verify")


def files(root):
    return {
        p.relative_to(root): p.read_bytes()
        for p in root.rglob("*")
        if p.is_file() and "__pycache__" not in p.parts
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--home",
        type=Path,
        default=Path.home(),
        help="Target home; use an isolated directory for tests",
    )
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    home = args.home.expanduser().resolve()
    repo = Path(__file__).resolve().parents[1]
    backup = (
        repo
        / ".memory/agent-defaults"
        / datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    )
    mismatches = []

    def retire(target):
        if target.exists() or target.is_symlink():
            if args.check:
                mismatches.append(str(target.relative_to(home)))
            else:
                backup.mkdir(parents=True, exist_ok=True)
                shutil.move(
                    str(target), str(backup / "--".join(target.relative_to(home).parts))
                )

    for name in SKILLS:
        source = repo / ".agents/skills" / name
        if not (source / "SKILL.md").is_file():
            raise SystemExit("Missing source: " + name)
        target = home / ".agents/skills" / name
        if files(source) != files(target):
            if args.check:
                mismatches.append(name)
            else:
                retire(target)
                shutil.copytree(
                    source, target, ignore=shutil.ignore_patterns("__pycache__")
                )
    for directory in (
        ".agents/skills",
        ".codex/skills",
        ".claude/skills",
        ".pi/agent/skills",
    ):
        for name in RETIRED:
            retire(home / directory / name)
    for name in ("frontend-design", "merged", "codex-goal-prompting"):
        retire(home / ".codex/skills" / name)

    for relative, source in (
        (".codex/AGENTS.md", repo / "universal/.codex/AGENTS.md"),
        (
            ".pi/agent/skills/herdr-pi/SKILL.md",
            repo / "universal/.pi/agent/skills/herdr-pi/SKILL.md",
        ),
    ):
        target = home / relative
        if not target.is_file() or target.read_bytes() != source.read_bytes():
            if args.check:
                mismatches.append(relative)
            else:
                retire(target)
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, target)

    config_path = home / ".codex/config.toml"
    config = config_path.read_text() if config_path.exists() else ""
    parsed = tomllib.loads(config)
    for key, default in (
        ("model", "gpt-6-astra"),
        ("model_reasoning_effort", "medium"),
    ):
        if key not in parsed:
            if args.check:
                mismatches.append(key)
            else:
                config = f'{key} = "{default}"\n' + config
    if not args.check and (
        not config_path.exists() or config_path.read_text() != config
    ):
        config_path.parent.mkdir(parents=True, exist_ok=True)
        config_path.write_text(config)
        config_path.chmod(0o600)

    lock_path = home / ".agents/.skill-lock.json"
    if lock_path.is_file():
        lock = json.loads(lock_path.read_text())
        entries = lock.get("skills", {})
        owned = set(entries).intersection((*SKILLS, *RETIRED))
        if args.check:
            mismatches.extend("external-updater:" + n for n in sorted(owned))
        elif owned:
            for name in owned:
                del entries[name]
            lock_path.write_text(json.dumps(lock, indent=2) + "\n")
    if mismatches:
        raise SystemExit("Defaults differ: " + ", ".join(mismatches))
    print(
        ("Verified" if args.check else "Installed")
        + f" {len(SKILLS)} curated skills; explicit model choices preserved."
    )


if __name__ == "__main__":
    main()
