# Herdr agent delegation runbook

Use these recipes only after choosing a Herdr-owned workflow. Worktrees and PR steps apply to Git writing slices that need isolation; creative work may use a pane in an ordinary project folder.

Use this when an agent needs to spawn, inspect, steer, or close out another
terminal-hosted coding agent.

## 1. Pick The Control Plane

Use Herdr when the work needs a terminal pane that can be checked later. Use
Codex thread tools when the user-visible ChatGPT Desktop thread is the ownership
boundary. For terminal-hosted agents, keep the work observable and resumable in
a Herdr pane instead of using a headless agent session.

Do not hide delegated work behind one-shot commands unless the user explicitly
asked for headless execution.

## 2. Create A Ledger

For repo work, create or update a `.memory/` ledger before delegation:

```markdown
# Herdr Ledger

| Owner | Pane/Agent | Cwd | Branch | PR | Status | Blocker | Next check |
| --- | --- | --- | --- | --- | --- | --- | --- |
| coordinator | local | /path/repo | main | n/a | active | none | now |
```

Keep this current enough that another agent can resume without guessing.

For Git slices that need isolation, the coordinator stays in the primary checkout. Give each writing owner one Herdr-created worktree and visible workspace. For creative outputs, use the intended project folder and explicit file ownership instead.
The implementation agent must not create worktrees or spawn nested agents.

## 3. Prove The Session Is Usable

Run both status and a real API command:

```bash
herdr --session default status server
herdr --session default workspace list
herdr --session default agent list
herdr --session default pane list
```

`status server` alone is not enough; stale sockets and just-exited servers can
still make status output misleading. Treat `workspace list` as the basic API
proof.

## 4. Create A Visible Workspace

Two cases. For work on an existing checkout, create a named workspace:

```bash
workspace_json="$(herdr --session default workspace create \
  --label my-nix-impl \
  --cwd /Users/anandpant/my-nix \
  --no-focus)"
workspace_id="$(printf '%s' "$workspace_json" | jq -r '.result.workspace.workspace_id')"
root_pane_id="$(printf '%s' "$workspace_json" | jq -r '.result.root_pane.pane_id')"
```

For branch-isolated work, use the NATIVE worktree flow instead — one command
creates the linked worktree (under `~/.herdr/worktrees/<repo>/<branch>`), the
workspace bound to it, and a root pane cd'd into the checkout:

```bash
wt_json="$(herdr --session default worktree create \
  --cwd /Users/anandpant/Development/nyrra/scryu \
  --branch fix-chat-origin-cors \
  --label scryu-chat-origin-cors \
  --no-focus)"
workspace_id="$(printf '%s' "$wt_json" | jq -r '.result.workspace.workspace_id')"
checkout="$(printf '%s' "$wt_json" | jq -r '.result.workspace.worktree.checkout_path')"
```

Never substitute raw `git worktree add`, `workspace create` pointed at a
hand-made checkout, or an agent's built-in worktree feature (Codex
`.codex/worktrees`, Claude EnterWorktree, etc.) when the user expects the work
visible in Herdr — those checkouts have no workspace binding and are invisible
in the spaces/agents panels.

Use labels that include the repo and role/purpose, such as `my-nix-impl`,
`scryu-review`, or `meshix-watch`.

## 5. Start The Agent

Use a stable agent name, the workspace id, and the repo/worktree cwd. A groomed
thin implementation slice defaults to `gpt-6-astra` with low reasoning. Use
medium only for a concrete remaining design or debugging uncertainty, and high
when warranted by the task. Preserve the user's explicit effort choice.

```bash
herdr agent start scryu-impl \
  --cwd "$checkout" \
  --workspace "$workspace_id" \
  --split right --no-focus \
  -- codex -m gpt-6-astra -c 'model_reasoning_effort="low"' \
    --disable multi_agent
```

Keep the user's selected model. Default new Codex work to Astra; use Sol only for bounded work the user selects. Choose effort for the task and preserve deliberately selected higher effort. Follow the global review policy rather than automatically creating a reviewer.

Before starting a review, resolve the smallest correct base:

- `main` or the exact merge-base for a standalone branch from `main`
- the immediate parent branch/PR head for a stacked PR
- the prior reviewed head for a follow-up review after fixes

Never repeatedly review a stacked or incremental PR against `main`. Record the
base, head, and tree in the ledger. Run the default Codex review in the visible
shell pane:

```bash
review_base="<resolved-base>"
review_pane_id="<visible-shell-pane-id>"
herdr pane run "$review_pane_id" "codex review --base $review_base"
```

After fixes, use the prior reviewed head as the next base and explicitly recheck
open findings. If Graphite rewrites only commit identity, compare the stable
patch id and effective diff against the new parent; do not rerun a model review
over unchanged code.

Start interactive agents first and submit prompts through their panes.
`herdr agent send` writes literal text only; do not use it to submit Codex or
Claude TUI prompts. If you intend to run a
shell command plus Enter, use `herdr pane run <pane_id> <command>`.

For implementation, tell the agent it is the sole slice owner, forbid nested
delegation and worktree creation, and require its final message to contain the
outcome, branch, commit, PR URL, tests, and blockers. The slice agent owns the
PR-ready implementation; the coordinator owns integration, final gates, merge,
and cleanup.

For PR watching, prefer the deterministic watcher script in one long-lived
command session, suppress unchanged output, and resume the same yielded process.
That path spends no model tokens while CI is simply pending. If interpretation
is useful, create a separate Terra-low monitor-only pane instead of changing the
coordinator's model. The watcher must exit and escalate on actionable
failure, review feedback, or ambiguity; the coordinator owns diagnosis and any
code change.

## 6. Check Up

Status semantics: `idle` (booted, not working), `working`, `blocked` (waiting
on approval/input — check the pane and answer it), `done` (finished, awaiting
review), `unknown` (no integration signal). Codex reports `done` on
completion, and `agent wait --status idle` also exits on `done` (0.7.1), so an
idle wait is a safe completion wait.

Use the agent target when Herdr knows it. The completion wait is a Herdr state
subscription, not a reason to poll status. After confirming the prompt reached
`working`, keep one task-sized waiter per active slice and use an hour for a
normal implementation slice:

```bash
herdr agent read scryu-impl --source recent --lines 200
herdr agent get scryu-impl
herdr agent wait scryu-impl --status idle --timeout 3600000
```

If the command host yields a running-process/session id, resume that same wait.
Do not replace it with repeated `agent list`, `agent get`, `agent read`, or
short `agent wait` calls. When it returns, read the final message once and
verify the reported branch, PR, tests, and blockers. On a real timeout,
diagnose once with `agent explain`, recent output, and process info before
re-arming a task-sized wait.

If the target is unclear:

```bash
herdr agent list
herdr pane list
herdr pane read <pane_id> --source recent --lines 200 --format text
herdr pane process-info --pane <pane_id>
```

`herdr agent explain <target> --json` is useful for integrated agents with a
detected label. It can be unavailable for plain shell commands or mock agents;
fall back to pane reads and process info.

Ids are non-durable and compact as things close: re-read workspace/tab/pane ids
from `list` output or creation JSON instead of reusing remembered ones.

## 7. Steer Safely

Read before sending, and submit every TUI message with enter:

```bash
herdr agent read scryu-impl --source recent --lines 200
herdr pane send-text <pane_id-from-agent-start> \
  "Status check: branch, tests run, PR, blockers, next action."
herdr pane send-keys <pane_id-from-agent-start> enter
```

For raw shell panes, `pane run` sends text plus Enter in one step:

```bash
herdr pane read <pane_id> --source recent --lines 200 --format text
herdr pane run <pane_id> "git status --short --branch"
herdr pane send-text <pane_id> "continue"
herdr pane send-keys <pane_id> enter
```

Use lowercase `enter`. Use `pane run` for shell commands. Use `pane send-text`
plus `pane send-keys ... enter` for interactive TUI prompts. If you need to
wait for command output, do not match text that appears in the echoed command.
Prefer a marker that appears at the start of the output line and verify with
`pane read`.

Notify the user at real milestones:

```bash
herdr notification show "scryu-impl done" --body "Tests green, PR up" --sound done
```

## 8. Close Out

Before closing a pane, capture the final state in the ledger:

- branch and PR URL
- tests and where they passed
- CI/review state
- remaining blocker, if any
- whether the pane should stay open for handoff

Close only when the owning work is terminal:

```bash
herdr workspace close <workspace_id>
```

For worktree workspaces, `worktree remove` deletes the checkout and closes the
workspace in one step (dirty trees need `--force`; capture uncommitted state
first, and delete the branch afterward if it is merged or abandoned):

```bash
herdr worktree remove --workspace <workspace_id>
```
