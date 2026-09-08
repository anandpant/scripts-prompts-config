---
name: babysit-pr
description: Watch a PR through required CI, actionable review feedback, and authorized merge or explicit handoff. Diagnose failures and fix in-scope branch defects while keeping one watcher owner.
---

# PR babysitting

Resolve the current PR, head, base, required checks, and review/merge authority from the task and repository. Watch the actual CI provider. The included helper handles GitHub Actions/checks and GitHub reviews; use the repository's native provider tools for Depot CI or other systems it does not cover.

Set `skill_dir` to the directory containing this loaded SKILL.md, then run its helper:

```sh
python3 "$skill_dir/scripts/gh_pr_watch.py" --pr auto --once
python3 "$skill_dir/scripts/gh_pr_watch.py" --pr auto --watch
```

Use `--watch` for sustained watching and `--once` for a single check or diagnosis. Keep one watcher per PR/state file; resume the same process when a tool yields. Do not add a model agent just to observe unchanged state. For a requested later follow-up, use an available Codex automation and preserve quiet/no-change behavior.

## Respond to changes

- Check actual merge/closed state first. Stop that watcher when terminal.
- Diagnose failed jobs as soon as logs exist. Distinguish branch defects from infrastructure failures. Patch only in-scope defects; do not change unrelated tests or infrastructure to make a check green.
- Read current actionable reviews. Keep independent review separate from implementation ownership. Recheck resolved findings only when new evidence warrants it; do not wait for hypothetical bots or repeatedly review an unchanged patch.
- Test fixes appropriately, commit, and submit through the repository's publication workflow, including Graphite when configured. Restart the same logical watcher on the new head and stop obsolete processes. Process review fixes before rerunning checks on an old head.
- Retry a demonstrated infrastructure flake only when the helper recommends `retry_failed_checks`, up to its three-retry budget. Use `--retry-failed-now`; do not invent unlimited reruns.
- Resolve a review thread only after its fix is published and verified. Do not send written replies to others without existing explicit authorization for that communication. If a response needs a decision, present the concrete proposed reply and explain the missing authority.

## Completion and ownership

When checks/review gates pass and merge is authorized, merge using the repository's workflow and verify the resulting state. If merge is reserved to someone else, keep the requested watch active or make an explicit handoff. A green snapshot alone does not finish a request to watch until merge.

Preserve unrelated local work and stay in the assigned checkout. Dirty state requires clarification only when ownership or a safe path is unclear. Do not silently stash, publish, or discard another task's work.

Report meaningful changes and blockers succinctly. Skip celebratory boilerplate and repetitive unchanged status. Do not end a turn claiming completion while leaving an owned watcher running. For an explicit handoff, stop or transfer that watcher and state who owns the remaining work.

See `references/heuristics.md` and `references/github-api-notes.md` for provider-specific diagnosis. Resolve all helper/reference paths relative to this skill, not the current checkout's `.codex` directory.
