# Agent guidelines

## Working together

Own the requested outcome. Investigate before guessing, keep changes focused, and continue authorized work through appropriate verification and handoff. Be succinct and direct; disagree when the evidence warrants it. Carry forward authorization for the same action and scope rather than repeatedly asking. Ask only for missing decisions or authority that materially changes the work. Report meaningful progress and blockers without repetitive narration.

Prefer the simplest correct solution. Preserve the user's intended meaning and audience. Remove superseded approaches as part of an intentional replacement; avoid unrequested compatibility machinery or unrelated refactors. Apply the concise unslop guidance to writing without adding a forced personality.

## Environment, delegation, and models

Stay in the environment where the user started. Codex-app work defaults to visible Codex threads and native worktrees when useful. Herdr work uses its panes when useful. Use Herdr from Codex when explicitly requested or when terminal agents, another provider, or remote terminal ownership need it. Delegation is optional; use it for independently useful work rather than as a mandatory ceremony.

Keep one owner for each shared output. Use Git worktrees only within a real repository and when source isolation helps. Video, audio, slides, research, and other creative work can stay in the project folder with distinct outputs. Do not initialize Git or require branches, worktrees, PRs, or code reviews merely because an artifact uses a script.

Use Astra for most real work and new Codex workers. Preserve the user's explicit model and effort choices; use Sol for bounded work the user selects. Choose reasoning effort for uncertainty and scope, preserving deliberately selected higher effort. Do not force a different model for editorial or browser work. Prefer deterministic watchers for unchanged CI state.

Use capabilities actually available in this session. Prefer visible threads to hidden subagents, and do not silently substitute hidden workers or force Herdr when thread tools are absent. Continue useful independent work and state a capability limitation when it affects requested delegation. In a Herdr-owned workflow, follow its workspace registration, send, wait, and ownership contract. Do not create nested delegation without a concrete need and assigned ownership.

## Verification and review

Reproduce meaningful defects before fixing them and add behavioral regression coverage where a test should have caught the bug. Run affected checks and required gates; do not rerun unchanged suites or expand testing without a new concern. Inspect the changed real entry point. A passing build or fixture does not prove hosted behavior, asset fidelity, or visual quality.

Review substantive code changes against the smallest correct base: the immediate stack parent, main for standalone work, or the last reviewed head for follow-up changes. Recheck findings and review new code when its risk warrants it. Do not repeatedly review unchanged patches; check stable patch identity after metadata-only rewrites. Independent reviewers stay read-only unless explicitly reassigned. For creative work, review content, rendering, playback, and exports as applicable; code review is optional unless material runtime risk warrants it.

Use agent-browser for public/local browser work and an available supported integration for existing signed-in sessions. Follow the selected tool's current contract. Verify the actual interaction and rendered result, including real console/page-error collection where applicable. Keep one owner per browser session or watcher.

## Frontend

Use the frontend-design skill for UI work. No all-caps eyebrow labels. Prefer recognizable icons, succinct user-facing copy, clear hierarchy, and progressive disclosure. Keep accessible names and enough labels to avoid ambiguity; never hide errors or required decisions to reduce clutter.

When a maintained TanStack solution fits a frontend capability, use it by default. Avoid direct useEffect/useLayoutEffect in product code; use framework lifecycle/data primitives, event handlers, or useSyncExternalStore. Isolate unavoidable third-party synchronization behind one reviewed adapter with an explicit lint exception.

## Tools and ownership

Check command availability before relying on a global CLI. Durable machine changes belong in the machine's configuration repository; use project-local tools for one-off repo work. Keep broader plugins and specialist skills scoped to projects that need them. Preserve credentials and unrelated user work.

## Git work

Apply branch/PR rules only to owned Git work. Inspect state first and preserve unrelated changes without making their publication or deletion a prerequisite for another task. Start a new branch from the updated primary checkout; preserve assigned worktrees and stack parents. Prefer Graphite when configured, with conventional branch/title prefixes and reviewable PRs. Verify actual CI/review/merge state instead of assuming dashboard settings. Complete merge when authorized and gates are satisfied, then clean up the owned branch/worktree through its originating environment. A read-only audit does not require branch changes or a PR.

Store temporary task evidence in .memory/ under the project, with .ignore allowing it to be inspected. Creative deliverables belong in their project directories. Do not change persistent memory without an explicit user request.
