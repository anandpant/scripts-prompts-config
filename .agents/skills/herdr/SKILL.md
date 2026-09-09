---
name: herdr
description: Use Herdr to inspect, start, read, send to, and wait on terminal-hosted agent panes and sessions, especially when coordinating Pi, Claude, Codex, OpenCode, Devin, or Cursor work inside a Herdr workspace. Includes the native worktree flow for isolated delegated branches.
---

# Herdr Agent Control

## Use This When

Use Herdr when delegated work is running, or should run, in terminal-hosted
panes:

- inspect active agent panes, statuses, cwd, and recent output
- start a new interactive agent in a pane
- submit follow-up prompt text to an interactive agent pane
- run commands in shell panes
- spawn an isolated worktree workspace for a delegated branch of work
- wait for an agent state or a specific output line
- recover long-running terminal work across local or remote Herdr sessions
- coordinate Pi, Claude, Codex, OpenCode, Devin, Cursor, or similar TUIs

Prefer first-class Codex thread tools for ChatGPT Desktop thread creation and
handoff when the user-visible Codex thread is the ownership boundary. Use Herdr
when the terminal workspace/pane layer is the control plane, including work
that must remain available for later inspection or follow-up.

## Read The Right Reference

- For normal delegation, checkups, steering, and closeout, read
  `references/agent-delegation-runbook.md`.
- For remote Herdr control over SSH aliases, read `references/remote-herdr.md`.
- For command failures, socket issues, stale sessions, or confusing agent state,
  read `references/troubleshooting.md`.

Use `scripts/smoke_check.sh` before relying on a Herdr session for important
work:

```bash
~/.agents/skills/herdr/scripts/smoke_check.sh --session default
```

## Operating Doctrine

Herdr is useful only when the user and later agents can see and steer the work
in the Herdr UI: one labeled space per delegated slice, with a named agent pane
whose status (working/blocked/done) is live in the agents panel. Keep that
observable path intact.

- Prove the API socket works with a real API command, not just `status server`.
- Start interactive TUI agents through Herdr panes for delegated work.
- Give each delegated pane a stable, role-specific name via `agent start`.
- Within a Herdr-owned Git workflow, create the checkout with `herdr worktree create` —
  never with raw `git worktree add` and never with an agent's own worktree
  feature (Codex `.codex/worktrees`, etc.). For this terminal workflow, Herdr-created worktrees bind
  to a visible workspace. See the runbook's worktree section.
- Read recent output before every follow-up.
- Send slash commands after startup, such as `/review ...`, instead of baking
  them into process argv. Use the pane id returned by `agent start`, then
  `pane send-text` followed by `pane send-keys ... enter`.
- Track pane id, agent name, cwd/worktree, branch, PR, status, blocker, and next
  action in `.memory/`.
- Treat all Herdr ids (workspace/tab/pane) as non-durable: they compact when
  things close. Re-read ids from `list` output or creation JSON; never reuse
  remembered ids across sessions.
- Use raw pane commands when an integration does not report an agent label.
- `agent send` writes literal text only; do not use it as a prompt submission
  primitive for Codex or Claude TUIs. Use `pane run` when shell command text
  plus Enter is intended.

Avoid progress-blind shortcuts for normal delegated work, including `codex exec`,
`claude -p`, `claude --print`, `claude --bg`, piping prompts into an agent, or
redirecting agent stdout. A bounded `codex review --base <resolved-base>` in a
visible Herdr pane is the normal review exception.

Upstream's official skill requires `HERDR_ENV=1` (control from inside a Herdr
pane). This machine's doctrine also allows outside-in control over the socket
CLI (`herdr --session default ...`) from any local shell; that is the normal
mode for coordinating agents here.

## Delegation scope

The global originating-app, model, and ownership policy decides whether Herdr is useful. Herdr does not require delegation, a Git repo, or a worktree for creative work. In a Git writing slice that needs isolation, use one Herdr-created worktree and visible workspace per owner. Otherwise start a pane in the intended project folder. Never initialize a repository merely to create a worktree.

Use Astra for new Codex workers unless the user selected a different model; Sol is for bounded work the user selects. Preserve selected effort. Do not automatically choose Claude for editorial work or create a separate review agent. Match review to the code risk or creative deliverable.

Give a worker its output scope, ownership boundaries, and relevant verification. Prevent overlapping writes and unnecessary nested delegation. Track only useful owner/status/output/blocker information. For Git work the owner may deliver a tested PR; for creative work it delivers inspected assets and source files.

## First Commands

Local session:

```bash
herdr --session default status server
herdr --session default workspace list
herdr --session default agent list
herdr --session default pane list
```

Remote session:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 omarchy 'herdr --session default status server'
ssh -o BatchMode=yes -o ConnectTimeout=5 omarchy 'herdr --session default workspace list'
ssh -o BatchMode=yes -o ConnectTimeout=5 omarchy 'herdr --session default pane list'
```

Native `herdr --remote <target>` is for interactive attach only. Do not use it
with subcommands such as `status server`. The agent standard for remote checkup
and steering is direct SSH into the machine that owns the Herdr session, then
plain `herdr --session default ...` on that host.

Canonical remote target names for agents:

- `omarchy` for Linux remote Herdr work.
- `babyomarchy` for lower-spec/tool-room Linux remote Herdr work.
- `macmini` for Mac mini work. Verify `command -v herdr` on that host before
  using it as a Herdr control plane.

## Worktree Workspaces (Native Flow)

One command creates the linked worktree, the workspace bound to it, and a root
pane already cd'd into the checkout:

```bash
herdr --session default worktree create \
  --cwd <repo-root> \
  --branch <branch-name> \
  --label <repo>-<purpose> \
  --no-focus
```

- Checkout lands under `~/.herdr/worktrees/<repo>/<branch>`.
- Parse `workspace_id` and the checkout path from the JSON result; start the
  agent with `--workspace <id> --cwd <checkout_path>`.
- An existing local branch is checked out as-is; otherwise the branch is
  created from `--base REF` or `HEAD`.
- Reattach a detached checkout with `worktree open --branch <name>`; clean up
  with `worktree remove --workspace <id>` (add `--force` for a dirty tree),
  which also closes the workspace. Delete the branch yourself afterward if it
  is fully merged or abandoned.

## Start Agents

Start the interactive agent first, record the pane id from the `agent start`
output, then submit the task through that pane:

```bash
herdr agent start <repo>-impl \
  --cwd <repo-or-worktree-path> \
  --workspace <workspace_id> \
  --split right --no-focus \
  -- codex -m gpt-6-astra -c 'model_reasoning_effort="low"' \
    --disable multi_agent

herdr agent wait <repo>-impl --status idle --timeout 60000
agent_pane_id="<pane-id-from-agent-start>"
herdr pane send-text "$agent_pane_id" \
  "You are the sole owner of this thin slice. Do not delegate, spawn subagents, or create worktrees. Implement and test it, commit it, push it, open or update its PR, then report outcome, branch, commit, PR URL, tests, and blockers."
herdr pane send-keys "$agent_pane_id" enter
herdr agent wait <repo>-impl --status working --timeout 30000
```

If the `working` wait times out, read the pane: the task text is almost
certainly sitting unsubmitted in the composer.

Preserve the user's selected model and effort. New Codex workers default to Astra; use Sol only for bounded work the user selects. Choose effort for uncertainty and scope without overriding a deliberate selection.
`--disable multi_agent` is mandatory for delegated Codex slice panes; it leaves
delegation available to the top-level coordinator while mechanically preventing
nested Codex subagents in the worktree.

Use stable names such as `<repo>-goal`, `<repo>-impl`, `<repo>-review`, or
`<repo>-watcher`, and workspace labels such as `<repo>-<purpose>`.

## Keep Reviews Incremental

Resolve and record the review base before launching the reviewer:

- A standalone PR branched from `main` uses `main` (or its exact merge-base).
- A stacked PR uses its immediate parent branch or parent PR head, never `main`.
- A follow-up after an already-reviewed head uses that reviewed SHA, and the
  reviewer also rechecks any still-open findings in their surrounding context.

Run the normal Codex review against that resolved base in a visible Herdr shell
pane:

```bash
review_base="<main-or-immediate-parent-or-reviewed-sha>"
review_pane_id="<visible-shell-pane-id>"
herdr pane run "$review_pane_id" "codex review --base $review_base"
```

Record the base, head, tree, and verdict in the ledger. After a fix, review only
`previous-reviewed-head..current-head`; do not rerun the entire PR. A Graphite
restack or squash invalidates commit identity, but if the stable patch id and
effective diff against the new parent are unchanged, verify that identity
instead of spending another model pass on identical code. Never transfer a
verdict when the patch changed.

## Watch PRs Without Burning Coordinator Context

Prefer the repository's deterministic PR watcher in one long-lived command
session. Suppress unchanged snapshots and resume the same yielded process; this
uses no model tokens while CI is merely pending. The coordinator keeps its
implementation context and handles only state changes, failures, reviews, or
merge conflicts.

When a model-backed watcher is genuinely useful, start a separate visible
Herdr lane with `gpt-5.6-terra` at low reasoning and `--disable multi_agent`.
Its prompt must say: monitor only, do not edit, commit, push, resolve comments,
or retry ambiguous failures; stop and escalate actionable state to the
coordinator. Do not switch the existing coordinator session to Terra, because
that discards its useful context and cache.

## Check Up And Steer

Agent status values: `idle` (present, not working), `working`, `blocked`
(waiting on input/approval), `done` (finished, awaiting review), `unknown`.
State authority differs by agent. Pi, OpenCode, and other lifecycle
integrations report semantic state directly. Claude and Codex hooks only report
session identity; Herdr detects their working, blocked, and idle states from the
live terminal screen. A current Claude or Codex hook therefore proves native
session restore, not completion delivery.

Use `agent wait` as the primary completion primitive. It subscribes to Herdr
state changes rather than polling pane output. `agent wait --status idle` also
returns when the pane reaches `done`, so it is the safe completion wait. Let one
task-sized wait block; use an hour for a normal implementation slice rather
than repeatedly checking every few minutes. If the command runner yields a
session id, resume that same waiter instead of starting repeated `agent list`,
`agent read`, or short `agent wait` calls. With multiple active slices, keep one
event waiter per slice when the host supports concurrent command sessions.
Herdr toast and sound notifications are user-facing; they do not inject a
completion callback into another agent pane.

Agent target (terminal id, unique agent name, detected label, or pane id):

```bash
herdr agent read <target> --source recent --lines 200
herdr agent get <target>
herdr agent wait <target> --status idle --timeout 3600000
herdr pane send-text <pane_id-from-agent-start> \
  "Status check: summarize current state, branch, tests, PR, and blockers."
herdr pane send-keys <pane_id-from-agent-start> enter
```

When the completion wait returns, read the final output once and verify the
reported branch, commit, PR, tests, and blockers. If the completion wait times
out, diagnose once before re-arming another task-sized wait:

```bash
herdr agent explain <target> --json
herdr agent read <target> --source recent --lines 200
herdr pane process-info --pane <pane_id>
```

A timeout while the pane still explains as `working` means the agent has not
completed; it is not evidence that a completion hook was dropped. Escalate a
state-detection problem only when the visible idle or blocked UI contradicts
`agent explain`.

Raw pane fallback:

```bash
herdr pane read <pane_id> --source recent --lines 200 --format text
herdr pane process-info --pane <pane_id>
herdr pane run <pane_id> "git status --short --branch"
herdr pane send-text <pane_id> "continue"
herdr pane send-keys <pane_id> enter
herdr wait agent-status <pane_id> --status done --timeout 3600000
```

Command distinctions:

- `agent send` / `pane send-text`: type text, no submit.
- `pane send-keys <pane> enter`: press keys (lowercase key names).
- `pane run <pane> <command>`: text plus Enter — right for shell panes, wrong
  for TUI composers when you want to review before submitting.
- `wait output --match` is for future output; `pane read` for what already
  happened. Avoid matching text echoed from the command itself; match an
  output-only line.

Ping the user when a milestone lands:

```bash
herdr notification show "meshix-impl done" --body "Branch pushed, tests green" --sound done
```

## Remote Checkups

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 omarchy \
  'herdr --session default agent read <target> --source recent --lines 200'
ssh -o BatchMode=yes -o ConnectTimeout=5 omarchy \
  'herdr --session default pane read <pane_id> --source recent --lines 200 --format text'
```

For read-only checkups, only run Herdr read/list/get/status/process-info
commands. Treat `agent start`, `agent send`, `pane send-*`, `pane run`,
`workspace create`, `worktree create/remove`, and `pane close` as mutations
that require ownership of that delegated slice.

## Safety Rules

- Always read recent output before sending follow-up instructions.
- Do not send destructive shell commands through Herdr unless the user asked for
  that exact operation.
- Keep one owner for each delegated slice.
- When a pane appears stuck, inspect live repo, PR, CI, and pane output before
  assuming the agent failed.
- Close panes only after the owning work is terminal: merged, abandoned, or
  intentionally handed off.
- `worktree remove` deletes the checkout; capture any uncommitted state first.

## Integration Checks

```bash
herdr integration status
herdr server agent-manifests --json
```

The my-nix baseline expects Herdr integrations for Claude, Codex, Devin,
OpenCode, and Pi. The Pi hook is Home Manager-owned in this
repo because their extension directories can be symlinked into the Nix store.
For Claude and Codex, also verify the active screen-detection manifest before
diagnosing completion waits; their integrations do not author lifecycle state.
