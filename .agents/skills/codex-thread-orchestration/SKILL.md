---
name: codex-thread-orchestration
description: Coordinate useful independent work in visible Codex threads, including ownership, handoff, and appropriate verification. Use when the task benefits from multiple threads or the user requests them.
---

# Codex thread orchestration

Follow the originating-app, model, and ownership policy in the global instructions. Delegation is optional. For Codex-app work, use available visible thread tools and native worktrees when isolation helps. If those tools are absent, continue independent work in the current thread and explain the limitation when it affects requested delegation. Do not silently substitute hidden agents or force Herdr.

Give each worker the outcome, scope, shared-output ownership, necessary context, and appropriate proof. Keep the user's selected model; default new workers to Astra. Use Sol only for bounded work the user selects. Keep one coordinator responsible for integration and unresolved work.

Use Git branches/worktrees only in actual repositories and when source isolation helps. Creative work can use named project folders and outputs. Do not create a repo or require a PR merely to delegate an asset or document.

For substantive code changes, decide whether independent review is useful and resolve the smallest correct base. Reviewers remain read-only unless explicitly reassigned. Recheck findings and review changed code when risk warrants it, without repeatedly reviewing unchanged patches. For creative work, review the actual content and deliverable.

Keep a concise record of active owners, output locations or branches/PRs, status, and blockers. Use one watcher per PR when watching is needed; follow repo CI/publication rules. Complete authorized integration and merge, then clean up owned work through its originating environment. Archive completed helper threads only when supported and appropriate.
