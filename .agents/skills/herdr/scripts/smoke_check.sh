#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: smoke_check.sh [--session NAME] [--pane-smoke]
       smoke_check.sh --remote SSH_TARGET [--remote-session NAME] [--pane-smoke]
       smoke_check.sh --session NAME --pane-smoke --keep-workspace --workspace-label LABEL

Checks that Herdr is reachable through the API socket. With --pane-smoke, also
creates a temporary workspace, sends a shell command to its pane, reads the
result, and closes the workspace unless --keep-workspace is set.
EOF
}

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "smoke_check.sh: missing required command: $1" >&2
    exit 127
  fi
}

quote_arg() {
  printf '%q' "$1"
}

session="default"
remote=""
remote_session=""
pane_smoke=0
keep_workspace=0
workspace_label=""
focus_workspace=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --session)
      session="${2:?--session requires a value}"
      shift 2
      ;;
    --remote)
      remote="${2:?--remote requires a value}"
      shift 2
      ;;
    --remote-session)
      remote_session="${2:?--remote-session requires a value}"
      shift 2
      ;;
    --pane-smoke)
      pane_smoke=1
      shift
      ;;
    --keep-workspace)
      keep_workspace=1
      shift
      ;;
    --workspace-label)
      workspace_label="${2:?--workspace-label requires a value}"
      shift 2
      ;;
    --focus)
      focus_workspace=1
      shift
      ;;
    *)
      echo "smoke_check.sh: unknown argument: $1" >&2
      usage >&2
      exit 64
      ;;
  esac
done

if [ -z "$remote_session" ]; then
  remote_session="$session"
fi

herdr_local() {
  herdr --session "$session" "$@"
}

herdr_remote() {
  local command="if ! command -v herdr >/dev/null 2>&1; then echo 'remote herdr not found on PATH' >&2; exit 127; fi; exec herdr --session $(quote_arg "$remote_session")"
  local arg

  for arg in "$@"; do
    command+=" $(quote_arg "$arg")"
  done

  ssh -o BatchMode=yes -o ConnectTimeout=5 "$remote" "$command"
}

wait_for_shell_output() {
  local runner="$1"
  local pane_id="$2"

  for _ in $(seq 1 40); do
    if "$runner" pane read "$pane_id" --source recent --lines 10 --format text 2>/dev/null | grep -q .; then
      return 0
    fi
    sleep 0.1
  done

  return 0
}

run_pane_smoke() (
  local runner="$1"
  local label="$2"
  local cwd="$3"
  local marker="$4"
  local create_json
  local focus_flag
  local workspace_id
  local pane_id
  local read_file

  need jq
  if [ "$focus_workspace" -eq 1 ]; then
    focus_flag="--focus"
  else
    focus_flag="--no-focus"
  fi

  create_json="$("$runner" workspace create --label "$label" --cwd "$cwd" "$focus_flag")"
  workspace_id="$(printf '%s' "$create_json" | jq -r '.result.workspace.workspace_id')"
  pane_id="$(printf '%s' "$create_json" | jq -r '.result.root_pane.pane_id')"
  read_file="$(mktemp)"

  cleanup() {
    if [ "$keep_workspace" -eq 0 ]; then
      "$runner" workspace close "$workspace_id" >/dev/null 2>&1 || true
    else
      echo "kept workspace=$workspace_id pane=$pane_id label=$label"
    fi
    rm -f "$read_file"
  }
  trap cleanup EXIT

  wait_for_shell_output "$runner" "$pane_id"
  "$runner" pane send-text "$pane_id" "printf \"$marker:%s\\n\" \"\$PWD\"" >/dev/null
  "$runner" pane send-keys "$pane_id" enter >/dev/null

  for _ in $(seq 1 50); do
    "$runner" pane read "$pane_id" --source recent --lines 80 --format text >"$read_file"
    if grep -q "^$marker:" "$read_file"; then
      grep "^$marker:" "$read_file"
      return 0
    fi
    sleep 0.1
  done

  echo "smoke_check.sh: pane smoke did not observe $marker output" >&2
  cat "$read_file" >&2
  return 1
)

if [ -n "$remote" ]; then
  need ssh
  remote_home="$(ssh -o BatchMode=yes -o ConnectTimeout=5 "$remote" 'printf %s "$HOME"')"

  echo "== remote ssh: $remote =="
  ssh -o BatchMode=yes -o ConnectTimeout=5 "$remote" 'printf "host=%s user=%s herdr=%s\n" "$(hostname)" "$(whoami)" "$(command -v herdr || true)"'

  echo "== remote herdr status: $remote session=$remote_session =="
  herdr_remote status server

  echo "== remote herdr api: $remote session=$remote_session =="
  herdr_remote workspace list >/dev/null
  echo "remote api reachable"

  if [ "$pane_smoke" -eq 1 ]; then
    run_pane_smoke herdr_remote "${workspace_label:-herdr-smoke-remote}" "$remote_home" HERDR_REMOTE_SMOKE
  fi
else
  need herdr
  echo "== local herdr status: session=$session =="
  herdr_local status server

  echo "== local herdr api: session=$session =="
  herdr_local workspace list >/dev/null
  echo "local api reachable"

  if [ "$pane_smoke" -eq 1 ]; then
    run_pane_smoke herdr_local "${workspace_label:-herdr-local-smoke}" "$PWD" HERDR_LOCAL_SMOKE
  fi
fi
