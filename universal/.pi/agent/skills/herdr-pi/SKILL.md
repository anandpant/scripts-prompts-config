---
name: herdr-pi
description: Pi-specific Herdr workflow. Use this instead of the generic herdr skill when Pi controls or observes terminal-hosted agent panes and sessions.
---

# Herdr Agent Control for Pi

This variant intentionally keeps Pi-specific launch models, prompt submission,
and timeout behavior. Do not replace it with the shared `~/.agents` version.

## Use This When

Use Herdr when you need to control or observe terminal-hosted agent work that is
running inside a Herdr workspace:

- inspect active agent panes and statuses
- start a new agent process in a pane
- send text to an agent or terminal pane
- read recent pane output
- wait for an agent to become idle, blocked, or done
- coordinate TUI-based agents when ACP/Codex thread tools are not the right
  surface

Prefer first-class Codex thread tools for Codex Desktop thread creation and
handoff when that is the better observable control plane. Prefer `acpx` for
persistent non-TUI ACP sessions when a pane is not useful. Use Herdr when you
want the terminal workspace/pane layer: native TUI behavior plus the ability to
read progress, send follow-ups, wait on state, and recover long-running work.

## Operating Doctrine

Herdr is the preferred surface for delegated terminal agents when progress
visibility matters.

- Start normal interactive TUI agents through Herdr panes.
- Specify model and reasoning/effort at launch for delegated goal,
  implementation, and review agents.
- Read recent pane output before each follow-up so instructions are grounded in
  current state.
- Send slash commands after startup, such as `/review ...`, instead of baking
  review or goal commands into the process argv.
- Track pane ids, agent names, branch names, PR links, status, blockers, and
  next actions in the repo `.memory/` ledger.
- Use another first-class control plane only when it keeps comparable progress
  visibility, such as Codex Desktop threads.

Avoid progress-blind shortcuts for normal delegated work, because they remove
the ability to check in, steer, or inspect live output. Examples include
`codex exec`, `codex review`, `codex app-server`, `claude -p`,
`claude --print`, `claude --bg`, piping prompts into `claude`, or redirecting
agent stdout. Use them only when the user explicitly asks for headless or
non-interactive execution.

## Quick Inspect

```bash
herdr status
herdr session list --json
herdr workspace list
herdr tab list
herdr pane list
herdr agent list
```

If `herdr agent list` is empty, inspect panes directly:

```bash
herdr pane list
herdr pane read <pane_id> --source recent --lines 80
herdr pane process-info --pane <pane_id>
```

## Start Agents

Start an agent in a named Herdr pane:

```bash
herdr agent start <name> --cwd <repo-path> --split right -- codex
herdr agent start <name> --cwd <repo-path> --split right -- claude
herdr agent start <name> --cwd <repo-path> --split right -- pi
herdr agent start <name> --cwd <repo-path> --split right -- opencode
```

Use stable, role-specific names such as `<repo>-impl`, `<repo>-review`, or
`<repo>-watcher`.

### Recommended Launches

Codex default for serious delegated goal, implementation, and review work:

```bash
herdr agent start <repo>-goal \
  --cwd <repo-path> \
  --split right \
  -- codex -m gpt-5.5 -c 'model_reasoning_effort="xhigh"'
```

Claude default for serious delegated goal, implementation, and review work:

```bash
herdr agent start <repo>-review \
  --cwd <repo-path> \
  --split right \
  -- claude --model claude-opus-4-8 --effort xhigh
```

Use Claude `max` effort only for hard or broad tasks where the user intent
justifies it. Do not use Claude Fable unless the user explicitly requests it;
when Fable is requested, cap effort at `high`.

Other agents can be started the same way: keep the Herdr flags before `--`, then
pass the agent-specific model, reasoning, permission, or config flags after
`--`.

## Send And Wait

For an agent target:

```bash
herdr agent send <target> "Status check: summarize current state and blockers."
herdr agent read <target> --source recent --lines 120
herdr agent wait <target> --status idle --timeout 600000
```

For a raw pane:

```bash
herdr pane run <pane_id> "git status --short --branch"
herdr pane send-text <pane_id> "continue"
herdr pane send-keys <pane_id> Enter
herdr wait output <pane_id> --match "ready" --lines 200 --timeout 300000
herdr wait agent-status <pane_id> --status idle --timeout 600000
```

Use `agent send` for literal text. Use `pane run` when you want command text
plus Enter. **Always include `--timeout` on `wait` calls; unbounded waits that
retry forever can EAGAIN the socket and break all herdr commands.**

### Review Flow

Primary Codex review flow:

```bash
herdr agent start <repo>-review \
  --cwd <repo-path> \
  --split right \
  -- codex -m gpt-5.5 -c 'model_reasoning_effort="xhigh"'

herdr agent send <repo>-review \
  "/review Review the current branch against main. Findings first."
herdr agent read <repo>-review --source recent --lines 200
herdr agent wait <repo>-review --status idle --timeout 600000
```

Use the same pattern for other slash-command-capable TUIs: start the interactive
agent first, then send the command text.

## Coordination Pattern

For larger work, use a goal/coordinator agent rather than a single large
implementation pane.

- Start one primary goal/coordinator agent in the default worktree.
- Have the coordinator decompose the goal into PR-sized slices.
- Start one implementation agent per slice.
- After implementation, start a separate review agent for that slice.
- Keep the coordinator responsible for pane ids, branches, PRs, blockers, CI,
  review feedback, merge state, cleanup, and final proof.
- Record the active ledger in `.memory/`, for example
  `.memory/herdr-ledger.md`.

## Safety Rules

- Always read recent output before sending follow-up instructions to a pane.
- Do not send destructive shell commands through Herdr unless the user asked for
  that exact operation.
- Keep one owner for each delegated slice. If a pane owns an implementation or
  review, track its pane id, agent name, branch, PR, and blocker in `.memory/`.
- When a pane appears stuck, inspect live repo/PR/CI state before assuming the
  agent is idle or failed.
- Close or archive completed panes only after the owning PR/thread/work is in a
  terminal state.

## Integration Checks

```bash
herdr integration status
```

The my-nix baseline expects Herdr integrations for Claude, Codex, Devin,
OpenCode, Cursor, OMP, and Pi. Pi and OMP hooks are Home Manager-owned in this
repo because their extension directories can be symlinked into the Nix store.
