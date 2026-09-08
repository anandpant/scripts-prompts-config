#!/usr/bin/env python3
"""Summarize local Codex automations without mutating them."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path

try:
    import tomllib
except ModuleNotFoundError:  # pragma: no cover
    import tomli as tomllib


def automation_files(codex_home: Path) -> list[Path]:
    base = codex_home / "automations"
    if not base.exists():
        return []
    return sorted(base.glob("*/automation.toml"))


def preview(text: str, limit: int = 180) -> str:
    compact = " ".join(text.split())
    return compact if len(compact) <= limit else compact[: limit - 1] + "..."


def summarize(path: Path) -> dict:
    data = tomllib.loads(path.read_text(encoding="utf-8"))
    prompt = str(data.get("prompt") or "")
    return {
        "path": str(path),
        "id": data.get("id"),
        "name": data.get("name"),
        "kind": data.get("kind"),
        "status": data.get("status"),
        "rrule": data.get("rrule"),
        "target_thread_id": data.get("target_thread_id"),
        "prompt_sha256": hashlib.sha256(prompt.encode("utf-8")).hexdigest(),
        "prompt_preview": preview(prompt),
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--codex-home",
        type=Path,
        default=Path(os.environ.get("CODEX_HOME", Path.home() / ".codex")),
    )
    parser.add_argument("--json", action="store_true", help="emit JSON array")
    args = parser.parse_args()

    rows = [summarize(path) for path in automation_files(args.codex_home)]
    if args.json:
        print(json.dumps(rows, indent=2, sort_keys=True))
        return
    for row in rows:
        print(
            "\t".join(
                str(row.get(key) or "")
                for key in (
                    "id",
                    "name",
                    "kind",
                    "status",
                    "rrule",
                    "target_thread_id",
                    "prompt_sha256",
                )
            )
        )


if __name__ == "__main__":
    main()
