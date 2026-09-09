# Remote Herdr Control

Use this when checking or steering Herdr sessions on another machine.

## Saved machines in Herdr 0.9

For one UI with Local and saved SSH machines, use `herdr machine add <ssh-target>
--label <label>` in an interactive terminal, then launch `herdr`. A profile
targets the remote default session unless `--remote-session <name>` is provided.
Use `herdr machine list --json` to discover profile IDs. Native profiles keep a
combined agent list and reconnect independently.

Setup can require installation or replacement of an older remote server.
Replacing that server can stop its panes; preserve active work and follow the
user's authority before accepting it. Do not automatically answer setup prompts.
Background reconnects do not install or restart servers.

Selecting a machine in the UI does not retarget an existing pane's CLI socket.
For automation, continue using explicit SSH and the intended remote session below.

## Standard Path

Run the Herdr CLI on the machine that owns the session. For remote sessions,
that means SSH plus plain `herdr`:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 omarchy \
  'herdr --session default workspace list'
```

Do not use target wrappers or helper wrappers in agent instructions. They create
too many names for the same operation.

Native `herdr --remote <target>` is interactive attach only. It cannot run
subcommands:

```bash
herdr --remote omarchy status server
```

That fails with:

```text
error: --remote can only be used with the default launch command
```

## Canonical Targets

- `omarchy`: standard Linux remote Herdr target.
- `babyomarchy`: standard lower-spec/tool-room Linux remote Herdr target.
- `macmini`: standard Mac mini target. First verify that `herdr` is on PATH
  before using it as a Herdr control plane.

Agent examples should use only those canonical target names.

## Readiness Check

First prove SSH and Herdr exist:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 omarchy \
  'printf "host=%s user=%s herdr=%s\n" "$(hostname)" "$(whoami)" "$(command -v herdr || true)"'
```

Then prove the session status and API:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 omarchy \
  'herdr --session default status server'
ssh -o BatchMode=yes -o ConnectTimeout=5 omarchy \
  'herdr --session default workspace list'
```

`status server` alone is not enough. `workspace list` proves the API socket can
serve real requests.

For a visible pane smoke that the user can inspect in Herdr:

```bash
~/.agents/skills/herdr/scripts/smoke_check.sh \
  --remote omarchy \
  --remote-session default \
  --pane-smoke \
  --keep-workspace \
  --workspace-label my-nix-remote-smoke
```

The script prints the retained workspace and pane ids. Record those in the repo
ledger and close them when the test or handoff is terminal.

## Remote Spawn And Checkup

Start a remote agent and record the pane id printed by `agent start`:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 omarchy \
  'herdr --session default agent start scryu-remote-review \
    --cwd /home/anandpant/Development/nyrra/scryu \
    --split right \
    -- codex'
```

Submit the prompt through that pane, then inspect by agent name:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 omarchy \
  'herdr --session default pane send-text <pane_id-from-agent-start> \
    "/review Review the current branch against main. Findings first."'
ssh -o BatchMode=yes -o ConnectTimeout=5 omarchy \
  'herdr --session default pane send-keys <pane_id-from-agent-start> enter'
ssh -o BatchMode=yes -o ConnectTimeout=5 omarchy \
  'herdr --session default agent read scryu-remote-review --source recent --lines 200'
```

`agent send` writes literal text only; do not use it to submit Codex or Claude
TUI prompts. Use `pane run` instead when shell command text plus Enter is
intended.

If the agent integration is not reporting a label, list panes and fall back to
the pane id:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 omarchy \
  'herdr --session default pane list'
ssh -o BatchMode=yes -o ConnectTimeout=5 omarchy \
  'herdr --session default pane read <pane_id> --source recent --lines 200 --format text'
```

## Read-Only Discipline

For checkups, use only read/list/get/status/process-info commands:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 omarchy \
  'herdr --session default agent list'
ssh -o BatchMode=yes -o ConnectTimeout=5 omarchy \
  'herdr --session default agent read <target> --source recent --lines 200'
ssh -o BatchMode=yes -o ConnectTimeout=5 omarchy \
  'herdr --session default pane process-info --pane <pane_id>'
```

Treat `agent start`, `agent send`, `pane send-*`, `workspace create`,
`workspace close`, and `pane close` as mutations. Only run them when the current
task owns that delegated slice or the user explicitly asked for the mutation.

## User-Visible Workspaces

When testing, spawning, or delegating real work, create a named Herdr workspace
instead of hiding the work in a temporary pane:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 omarchy \
  'herdr --session default workspace create \
    --label my-nix-review \
    --cwd /home/anandpant/my-nix \
    --no-focus'
```

Use a label that includes the repo and role, such as `my-nix-review`,
`scryu-impl`, or `meshix-watch`. Put the workspace id and pane id in `.memory/`
so a later agent can check up without rediscovery.
