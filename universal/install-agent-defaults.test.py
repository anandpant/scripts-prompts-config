#!/usr/bin/env python3
import subprocess
from pathlib import Path
import tempfile
import unittest

SCRIPT = Path(__file__).with_name("install-agent-defaults.py")


class InstallTests(unittest.TestCase):
    def test_preserves_choice_retires_copy_and_checks_install(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            (home / ".codex").mkdir()
            config = home / ".codex/config.toml"
            original = 'model = "gpt-5.6-sol"\nmodel_reasoning_effort = "high"\n'
            config.write_text(original)
            retired = home / ".codex/skills/taste-skill"
            retired.mkdir(parents=True)
            (retired / "SKILL.md").write_text("old")
            for flags in [[], ["--check"], []]:
                subprocess.run(
                    ["python3", str(SCRIPT), "--home", directory, *flags],
                    check=True,
                    capture_output=True,
                )
            self.assertEqual(config.read_text(), original)
            self.assertFalse(retired.exists())
            (home / ".agents/skills/unslop/SKILL.md").write_text("drift")
            result = subprocess.run(
                ["python3", str(SCRIPT), "--home", directory, "--check"],
                capture_output=True,
            )
            self.assertNotEqual(result.returncode, 0)

    def test_new_install_uses_astra(self):
        with tempfile.TemporaryDirectory() as directory:
            subprocess.run(
                ["python3", str(SCRIPT), "--home", directory],
                check=True,
                capture_output=True,
            )
            self.assertIn(
                "gpt-6-astra", (Path(directory) / ".codex/config.toml").read_text()
            )


if __name__ == "__main__":
    unittest.main()
