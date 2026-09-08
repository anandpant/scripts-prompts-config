#!/usr/bin/env python3
"""Exercise Herdr smoke cleanup through its shell entrypoint."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = (
    Path(__file__).resolve().parents[1]
    / ".agents/skills/herdr/scripts/smoke_check.sh"
)
FAKE = """#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
args = sys.argv[3:]
root = Path(os.environ["HERDR_TEST_ROOT"])
if args[:2] == ["workspace", "create"]:
    print(json.dumps({"result": {"workspace": {"workspace_id": "owned"}, "root_pane": {"pane_id": "pane"}}}))
elif args[:2] == ["workspace", "close"]:
    (root / "closed").write_text(args[2])
elif args[:2] == ["pane", "send-text"]:
    if os.environ["FAIL_AT"] == "send-text": sys.exit(23)
elif args[:2] == ["pane", "send-keys"]:
    if os.environ["FAIL_AT"] == "send-keys": sys.exit(23)
    (root / "sent").touch()
elif args[:2] == ["pane", "read"]:
    if "80" in args and os.environ["FAIL_AT"] == "read": sys.exit(23)
    print("HERDR_LOCAL_SMOKE:/project" if (root / "sent").exists() else "shell ready")
"""


class SmokeTests(unittest.TestCase):
    def test_owned_resources_cleaned_on_success_and_failure(self):
        for failure in ("", "send-text", "send-keys", "read"):
            for keep in (False, True):
                with (
                    self.subTest(failure=failure, keep=keep),
                    tempfile.TemporaryDirectory() as directory,
                ):
                    root = Path(directory)
                    temp = root / "temp"
                    temp.mkdir()
                    fake = root / "herdr"
                    fake.write_text(FAKE)
                    fake.chmod(0o755)
                    env = dict(
                        os.environ,
                        PATH=str(root) + os.pathsep + os.environ["PATH"],
                        TMPDIR=str(temp),
                        HERDR_TEST_ROOT=str(root),
                        FAIL_AT=failure,
                    )
                    result = subprocess.run(
                        [
                            "bash",
                            str(SCRIPT),
                            "--pane-smoke",
                            *(["--keep-workspace"] if keep else []),
                        ],
                        env=env,
                        capture_output=True,
                        text=True,
                    )
                    self.assertEqual(
                        result.returncode, 23 if failure else 0, result.stderr
                    )
                    self.assertEqual((root / "closed").exists(), not keep)
                    self.assertEqual(list(temp.iterdir()), [])


if __name__ == "__main__":
    unittest.main()
