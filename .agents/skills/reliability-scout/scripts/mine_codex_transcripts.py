#!/usr/bin/env python3
"""Screen local transcripts for reviewable candidates, not inferred preferences."""

from __future__ import annotations

import argparse
import csv
from datetime import date
import hashlib
import json
from pathlib import Path
import re
import sqlite3
from collections import Counter, defaultdict

TOPICS = {
    "workflow": r"\b(herdr|worktrees?|threads?|graphite|delegat\w*|review|astra|sol)\b",
    "writing_and_visuals": r"\b(unslop|succinct|sterile|generic|visual|diagram|wording|tone)\b|too many words|fewer words",
    "correction_candidate": r"\b(confus\w*|contradict\w*|stuck|struggl\w*)\b|i (already|said|asked|told)|keep asking|not working|too (much|many)|real proof",
    "instructions": r"\b(skills?|plugins?|instructions?|memory|AGENTS\.md)\b",
    "verification": r"\b(test\w*|ci|lint|typecheck|e2e|proof|verify|verification)\b",
}
TOPICS = {name: re.compile(pattern, re.I) for name, pattern in TOPICS.items()}
WRAPPERS = (
    "# AGENTS.md instructions",
    "<recommended_plugins>",
    "<environment_context>",
    "<in-app-browser-context",
    "<subagent_notification>",
    "<turn_aborted>",
    "<skill>",
    "<external_codex_apps_",
    "<permissions instructions>",
)


def text_parts(content):
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return "\n".join(
            p["text"]
            for p in content
            if isinstance(p, dict) and isinstance(p.get("text"), str)
        )
    return ""


def classify(text, source):
    """Source metadata wins; textual classifications remain candidates."""
    if text.startswith(("<heartbeat>", "<automation", "Automation:")):
        return "automation"
    if text.startswith("<user_action>") and "<action>review</action>" in text:
        return "review"
    if isinstance(source, dict) and "subagent" in source:
        return "delegated"
    if text.startswith("<codex_delegation>"):
        return "delegated"
    if re.search(
        r"^(You are|Sole |Own (issue|a |the |PR)|Perform one|Read-only|Review (PR|the|current)|Continue ownership|Take ownership)|sole implementation owner|Coordinator owns",
        text,
        re.I,
    ):
        return "delegated_candidate"
    if text.startswith("<") and not text.startswith(
        "<send_user_message_question_reply>"
    ):
        return "ambiguous"
    return "human_candidate"


def thread_metadata(home):
    db = home / "state_5.sqlite"
    if not db.exists():
        return {}
    con = sqlite3.connect(f"{db.as_uri()}?mode=ro", uri=True)
    try:
        con.row_factory = sqlite3.Row
        return {
            r["id"]: dict(r) for r in con.execute("select id, title, cwd from threads")
        }
    except sqlite3.Error:
        return {}
    finally:
        con.close()


def scan(path, metadata, since=None, until=None):
    session = {}
    model = ""
    with path.open(errors="replace") as stream:
        for line_number, line in enumerate(stream, 1):
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue  # An active rollout can end in a partially written line.
            payload = obj.get("payload") or {}
            if obj.get("type") == "session_meta":
                session = payload
                model = payload.get("model", "")
                continue
            if obj.get("type") == "turn_context":
                model = payload.get("model", model)
                continue
            sid = session.get("id") or session.get("session_id")
            if not sid:
                continue
            timestamp = obj.get("timestamp", "")
            day = timestamp[:10]
            if (since and day < since) or (until and day > until):
                continue
            meta = metadata.get(sid, {})
            base = dict(
                thread_id=sid,
                title=meta.get("title", ""),
                cwd=meta.get("cwd") or session.get("cwd", ""),
                model=model,
                originator=session.get("originator", ""),
                source=json.dumps(session.get("source", "")),
                path=str(path),
                line=line_number,
                timestamp=timestamp,
            )
            if obj.get("type") == "event_msg" and payload.get("type") == "token_count":
                info = payload.get("info") or {}
                yield dict(
                    base,
                    record="tokens",
                    total=info.get("total_token_usage", {}),
                    last=info.get("last_token_usage", {}),
                )
                continue
            if obj.get("type") != "response_item" or payload.get("type") != "message":
                continue
            role = payload.get("role")
            channel = payload.get("channel", "")
            if role not in ("user", "assistant") or (
                role == "assistant" and channel not in ("", None, "commentary", "final")
            ):
                continue
            text = text_parts(payload.get("content")).strip()
            if role == "user":
                if (
                    text.startswith("<in-app-browser-context")
                    and "## My request:" in text
                ):
                    text = text.split("## My request:", 1)[1].strip()
                if text.startswith(WRAPPERS):
                    continue
            if not text:
                continue
            kind = (
                classify(text, session.get("source")) if role == "user" else "assistant"
            )
            topics = [name for name, pattern in TOPICS.items() if pattern.search(text)]
            yield dict(
                base,
                record="message",
                role=role,
                channel=channel or "unspecified",
                kind=kind,
                topics=";".join(topics),
                text=text,
            )


def write_csv(path, rows, fields):
    with path.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--codex-home", type=Path, default=Path.home() / ".codex")
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--max-files", type=int, default=650)
    parser.add_argument(
        "--since", type=date.fromisoformat, help="Inclusive UTC date, YYYY-MM-DD"
    )
    parser.add_argument(
        "--until", type=date.fromisoformat, help="Inclusive UTC date, YYYY-MM-DD"
    )
    args = parser.parse_args()
    if args.max_files < 1 or (args.since and args.until and args.since > args.until):
        parser.error("Use a positive file limit and an ordered date window")
    home = args.codex_home.expanduser().resolve()
    files = sorted(
        (
            p
            for root in (home / "sessions", home / "archived_sessions")
            for p in root.rglob("rollout-*.jsonl")
        ),
        key=lambda p: p.stat().st_mtime,
        reverse=True,
    )[: args.max_files]
    metadata = thread_metadata(home)
    seen = set()
    counts = Counter()
    user_rows, assistant_rows = [], []
    tokens = {}
    thread_topics = defaultdict(set)
    for path in files:
        for row in scan(
            path,
            metadata,
            str(args.since) if args.since else None,
            str(args.until) if args.until else None,
        ):
            sid = row["thread_id"]
            if row["record"] == "tokens":
                if sid not in tokens or row["timestamp"] > tokens[sid]["timestamp"]:
                    tokens[sid] = row
                continue
            identity = (
                sid,
                row["timestamp"],
                row["role"],
                row["channel"],
                hashlib.sha256(row["text"].encode()).hexdigest(),
            )
            if identity in seen:
                counts["duplicate_messages_skipped"] += 1
                continue
            seen.add(identity)
            counts[row["kind"]] += 1
            if not row["topics"]:
                continue
            row["excerpt"] = re.sub(r"\s+", " ", row.pop("text"))[:800]
            if row["role"] == "user":
                user_rows.append(row)
                if row["kind"] == "human_candidate":
                    for topic in row["topics"].split(";"):
                        thread_topics[topic].add(sid)
            elif "correction_candidate" in row["topics"].split(";"):
                assistant_rows.append(row)
    args.out.mkdir(parents=True, exist_ok=True)
    fields = [
        "thread_id",
        "title",
        "cwd",
        "model",
        "originator",
        "source",
        "role",
        "channel",
        "kind",
        "timestamp",
        "path",
        "line",
        "topics",
        "excerpt",
    ]
    write_csv(args.out / "topic-message-candidates.csv", user_rows, fields)
    write_csv(args.out / "assistant-struggle-candidates.csv", assistant_rows, fields)
    token_rows = [
        dict(row, total=json.dumps(row["total"]), last=json.dumps(row["last"]))
        for row in tokens.values()
    ]
    write_csv(
        args.out / "token-usage-samples.csv",
        token_rows,
        ["thread_id", "model", "timestamp", "path", "line", "total", "last"],
    )
    summary = dict(
        rollouts_scanned=len(files),
        since=str(args.since) if args.since else None,
        until=str(args.until) if args.until else None,
        message_classifications=dict(counts),
        user_message_candidates=len(user_rows),
        assistant_struggle_candidates=len(assistant_rows),
        human_candidate_topic_threads={k: len(v) for k, v in thread_topics.items()},
        token_sample_count=len(tokens),
        limitations="Candidates require contextual review. Text heuristics do not establish human authorship, preferences, failures, model quality, or avoidable cost. Token snapshots are historical cumulative counters, not spend or savings. Files are sampled by modification time; date filtering applies to events.",
    )
    (args.out / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
