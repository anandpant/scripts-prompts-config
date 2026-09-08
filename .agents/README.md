# Repo-owned agent defaults

`.agents/skills` owns portable skill sources. `universal/.codex/AGENTS.md` owns
shared behavior. Preserve explicit app model/effort choices; Astra is the new
installation default and Sol is for bounded work the user selects.

After reviewing and merging updates, install the curated defaults with:

```sh
python3 universal/install-agent-defaults.py
python3 universal/install-agent-defaults.py --check
```

The installer copies only its named, repo-owned skills into the shared directory,
removes their old external update registrations, and retires duplicate taste,
browser-verification, frontend, and merged discovery entries. Replaced runtime
copies are retained outside skill discovery under repo `.memory/agent-defaults`.
It does not copy account credentials or overwrite model selections. Other skills
and plugins remain independently installed.

Use the normal skills installer with explicit skill/agent names for optional
upstream capabilities. Do not install every available skill by default.
