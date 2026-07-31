#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"

script_path="$(readlink -f "${BASH_SOURCE[0]}")"
repo_root="$(cd "$(dirname "$script_path")/.." && pwd)"
helper="$repo_root/universal/clipboard-shell-tools.sh"

install_xclip_without_root() {
  local tmp package
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN
  (
    cd "$tmp"
    apt-get download xclip
    package="$(find . -maxdepth 1 -name 'xclip_*.deb' -print -quit)"
    dpkg-deb -x "$package" extracted
    install -Dm755 extracted/usr/bin/xclip "$HOME/.local/bin/xclip"
  )
  trap - RETURN
  rm -rf "$tmp"
}

install_backend() {
  if [ -n "${WAYLAND_DISPLAY:-}" ] && [ -S "${XDG_RUNTIME_DIR:-/nonexistent}/${WAYLAND_DISPLAY}" ]; then
    command -v wl-copy >/dev/null 2>&1 && return
    if command -v pacman >/dev/null 2>&1; then
      sudo pacman -S --needed wl-clipboard
    elif command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update && sudo apt-get install -y wl-clipboard
    else
      printf 'Install wl-clipboard, then rerun this script.\n' >&2
      exit 1
    fi
  elif [ -n "${DISPLAY:-}" ]; then
    command -v xclip >/dev/null 2>&1 && return
    if command -v apt-get >/dev/null 2>&1; then
      if [ "$(id -u)" -eq 0 ]; then
        apt-get update && apt-get install -y xclip
      elif sudo -n true >/dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y xclip
      else
        # DGX and other managed hosts may grant no sudo. xclip is a small,
        # dynamically linked binary, so install the distro package payload locally.
        install_xclip_without_root
      fi
    elif command -v pacman >/dev/null 2>&1; then
      sudo pacman -S --needed xclip
    else
      printf 'Install xclip or xsel, then rerun this script.\n' >&2
      exit 1
    fi
  else
    printf 'No active Wayland or X11 display was detected. Run this inside the graphical session.\n' >&2
    exit 1
  fi
}

add_shell_source() {
  local rc="$1"
  local source_line='[ -f "$HOME/scripts-prompts-config/universal/clipboard-shell-tools.sh" ] && . "$HOME/scripts-prompts-config/universal/clipboard-shell-tools.sh"'
  touch "$rc"
  if ! grep -Fq 'universal/clipboard-shell-tools.sh' "$rc"; then
    printf '\n# Portable pbcopy/pbpaste (Wayland and X11)\n%s\n' "$source_line" >> "$rc"
  fi
}

install_backend
add_shell_source "$HOME/.bashrc"
add_shell_source "$HOME/.zshrc"

# Verify in this process without requiring a new terminal.
# shellcheck source=clipboard-shell-tools.sh
. "$helper"
printf 'clipboard setup test' | pbcopy
copied="$(pbpaste)"
if [ "$copied" != 'clipboard setup test' ]; then
  printf 'Clipboard verification failed (read back: %s).\n' "$copied" >&2
  exit 1
fi

printf 'Clipboard configured and verified. Open a new shell or source ~/.bashrc (or ~/.zshrc).\n'
