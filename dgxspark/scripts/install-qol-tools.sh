#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/.local/bin:$HOME/.atuin/bin:$PATH"

# Install architecture-matched release binaries in user space. mise keeps the
# versions reproducible without vendoring ARM64 binaries in this repository.
if ! command -v mise >/dev/null 2>&1; then
  installer="$(mktemp)"
  trap 'rm -f "$installer"' EXIT
  curl -fsSL https://mise.run -o "$installer"
  sh "$installer"
  rm -f "$installer"
  trap - EXIT
fi

mise use -g \
  github:eza-community/eza@latest \
  github:sharkdp/bat@latest \
  github:junegunn/fzf@latest \
  github:neovim/neovim@latest

if ! command -v atuin >/dev/null 2>&1 && [ ! -x "$HOME/.atuin/bin/atuin" ]; then
  installer="$(mktemp)"
  trap 'rm -f "$installer"' EXIT
  curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh -o "$installer"
  sh "$installer" --non-interactive
  rm -f "$installer"
  trap - EXIT
fi

printf 'Installed fzf, eza, bat, mise, atuin, and neovim for %s in user space.\n' "$(uname -m)"
