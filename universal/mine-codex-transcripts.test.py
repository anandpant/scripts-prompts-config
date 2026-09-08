#!/usr/bin/env python3
import csv
import json
import io
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = (
    Path(__file__).resolve().parents[1]
    / ".agents/skills/reliability-scout/scripts/mine_codex_transcripts.py"
)


class TranscriptTests(unittest.TestCase):
    def test_cli_provenance_classification_window_and_duplicate_history(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            sessions = root / "sessions"
            sessions.mkdir()

            def event(typ, payload, day="2026-09-08"):
                return (
                    json.dumps(
                        dict(type=typ, payload=payload, timestamp=day + "T12:00:00Z")
                    )
                    + "\n"
                )

            def message(text, role="user", channel=None, day="2026-09-08"):
                return event(
                    "response_item",
                    dict(
                        type="message",
                        role=role,
                        channel=channel,
                        content=[dict(text=text)],
                    ),
                    day,
                )

            records = event(
                "session_meta",
                dict(id="same-thread", originator="desktop", source="vscode"),
            )
            records += event("turn_context", dict(model="gpt-6-astra"))
            records += message(
                "<recommended_plugins>skills and tests</recommended_plugins>"
            )
            records += message(
                "<in-app-browser-context>test</in-app-browser-context>\n## My request:\nPlease use fewer words"
            )
            records += message("You are the sole implementation owner. Run tests")
            records += message(
                "<user_action><action>review</action>test findings</user_action>"
            )
            records += message("<heartbeat>test the CI</heartbeat>")
            records += message(
                "I am stuck reasoning", role="assistant", channel="analysis"
            )
            records += message("The test is stuck", role="assistant", channel="final")
            records += message("Please test old behavior", day="2026-08-01")
            records += event(
                "event_msg",
                dict(
                    type="token_count",
                    info=dict(total_token_usage=dict(total_tokens=50)),
                ),
            )
            (sessions / "rollout-a.jsonl").write_text(records + "{")
            (sessions / "rollout-resumed.jsonl").write_text(records)
            out = root / "out"
            subprocess.run(
                [
                    "python3",
                    str(SCRIPT),
                    "--codex-home",
                    str(root),
                    "--out",
                    str(out),
                    "--since",
                    "2026-09-08",
                    "--until",
                    "2026-09-08",
                ],
                check=True,
                capture_output=True,
            )
            rows = list(
                csv.DictReader(
                    io.StringIO((out / "topic-message-candidates.csv").read_text())
                )
            )
            self.assertEqual(len(rows), 4)
            self.assertEqual(
                {r["kind"] for r in rows},
                {"human_candidate", "delegated_candidate", "review", "automation"},
            )
            human = next(r for r in rows if r["kind"] == "human_candidate")
            self.assertEqual(human["excerpt"], "Please use fewer words")
            self.assertEqual(human["line"], "4")
            self.assertEqual(human["model"], "gpt-6-astra")
            self.assertTrue(Path(human["path"]).is_file())
            assistants = list(
                csv.DictReader(
                    io.StringIO((out / "assistant-struggle-candidates.csv").read_text())
                )
            )
            self.assertEqual(len(assistants), 1)
            self.assertEqual(assistants[0]["channel"], "final")
            summary = json.loads((out / "summary.json").read_text())
            self.assertEqual(summary["token_sample_count"], 1)
            self.assertGreater(
                summary["message_classifications"]["duplicate_messages_skipped"], 0
            )

    def test_invalid_window_fails(self):
        result = subprocess.run(
            [
                "python3",
                str(SCRIPT),
                "--out",
                "unused",
                "--since",
                "2026-09-08",
                "--until",
                "2026-08-01",
            ],
            capture_output=True,
        )
        self.assertNotEqual(result.returncode, 0)


if __name__ == "__main__":
    unittest.main()
