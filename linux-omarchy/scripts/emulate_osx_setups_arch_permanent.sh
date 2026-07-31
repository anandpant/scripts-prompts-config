#!/usr/bin/env bash
# Backward-compatible entry point. The replacement supports Wayland and X11,
# Arch and Debian/Ubuntu, and configures both Bash and Zsh idempotently.
set -euo pipefail
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/setup-clipboard.sh" "$@"
