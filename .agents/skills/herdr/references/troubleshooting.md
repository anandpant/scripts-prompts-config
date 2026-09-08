# Herdr Troubleshooting

## `agent start` Fails: No Viable Candidates Found In PATH

Cause: the Herdr server can run with a minimal PATH (seen on Linux:
`/usr/local/bin:/usr/bin`), so agent binaries in `~/.local/bin` are not found
when spawning.

Fix: pass the absolute binary path in the argv and set PATH for the pane:

```bash
herdr agent start <name> --workspace <id> --cwd <path> --split right --no-focus \
  --env "PATH=$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin" \
  -- $HOME/.local/bin/codex --yolo -m gpt-6-astra -c 'model_reasoning_effort="medium"'
```

## Delegated Worktree Is Invisible In The Herdr UI

Cause: the worktree was created outside Herdr — raw `git worktree add`, Codex's
own `.codex/worktrees`, or Claude's EnterWorktree — so no Herdr workspace is
bound to it. The agent may be running, but nothing shows in the spaces/agents
panels.

Fix: create the checkout with the native flow, then start the agent inside the
returned workspace:

```bash
herdr --session default worktree create --cwd <repo-root> --branch <name> --label <repo>-<purpose> --no-focus
herdr agent start <name> --workspace <workspace_id> --cwd <checkout_path> --split right --no-focus -- <argv...>
```

To adopt an existing external checkout, `herdr worktree open --path <checkout>`
binds it to a new workspace. Clean up stale external checkouts with
`git worktree list` in the main repo.

## `--remote can only be used with the default launch command`

Cause: native `herdr --remote <target>` only attaches interactively.

Fix: run the Herdr command on the remote host through SSH:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 omarchy \
  'herdr --session default status server'
ssh -o BatchMode=yes -o ConnectTimeout=5 omarchy \
  'herdr --session default workspace list'
```

## `status server` Looks Good But Commands Fail

Cause: the status output is not enough proof that the API socket can serve
requests. A server may have just exited, or stale sockets may be present.

Fix: always run a real API command:

```bash
herdr --session default status server
herdr --session default workspace list
```

If `workspace list` fails with connection errors, attach to the session or start
the durable fleet session, then retry:

```bash
herdr-fleet --no-attach
herdr --session fleet workspace list
```

## Named Session Versus Default Session

`--session omarchy` and `--session default` are different sessions. For agents,
use `--session default` unless the user or existing ledger names another
session.

Fix:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 omarchy \
  'herdr --session default status server'
ssh -o BatchMode=yes -o ConnectTimeout=5 omarchy \
  'herdr --session omarchy status server'
```

## `agent explain` Is Unavailable

Cause: the pane does not have a detected agent label. This is normal for plain
shells, mock agents, or integrations that have not reported state yet.

Fix:

```bash
herdr agent list
herdr pane list
herdr pane read <pane_id> --source recent --lines 200 --format text
herdr pane process-info --pane <pane_id>
```

## Wait Matched The Echoed Command

Cause: terminal panes echo the command text, so `wait output --match MARKER` can
match the command line before the command result exists.

Fix: read the pane and match an output-only line, usually a marker at the start
of the line:

```bash
herdr pane read <pane_id> --source recent --lines 80 --format text
```

## `agent send` Wrote Text But Did Not Submit

Cause: `herdr agent send <target> <text>` writes literal text. It is not the
right primitive for submitting prompts or slash commands to interactive Codex or
Claude TUIs.

Fix: use the pane id returned by `agent start`, then send text and press Enter:

```bash
herdr pane send-text <pane_id-from-agent-start> \
  "/review Review the current branch against main. Findings first."
herdr pane send-keys <pane_id-from-agent-start> enter
```

If you intend to run shell command text plus Enter, use `pane run` instead:

```bash
herdr pane run <pane_id> "git status --short --branch"
```

## `pane send-keys Enter` Does Nothing

Use lowercase key names:

```bash
herdr pane send-keys <pane_id> enter
```

For interactive TUI prompt text, use `pane send-text` plus lowercase
`pane send-keys ... enter`:

```bash
herdr pane send-text <pane_id> "continue"
herdr pane send-keys <pane_id> enter
```

## Remote `herdr` Not Found On PATH

Cause: SSH works, but the remote host does not expose a `herdr` binary in the
non-interactive SSH environment.

Fix: activate/install Herdr on the remote host, or update that host's SSH login
environment so `command -v herdr` succeeds:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 <target> 'command -v herdr'
```

## Config Permission Error 13

Cause: `~/.config/herdr/config.toml` may still be a read-only symlink from an
older activation.

Fix: make the live config writable, then let Home Manager seed it only when
missing.
