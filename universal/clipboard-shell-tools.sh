# Cross-platform macOS-style clipboard commands for Bash and Zsh.
# Prefer the active display backend instead of assuming that Linux uses Wayland.

unalias pbcopy pbpaste 2>/dev/null || true

_clipboard_has_wayland() {
  [ -n "${WAYLAND_DISPLAY:-}" ] &&
    [ -n "${XDG_RUNTIME_DIR:-}" ] &&
    [ -S "${XDG_RUNTIME_DIR}/${WAYLAND_DISPLAY}" ]
}

pbcopy() {
  if _clipboard_has_wayland && command -v wl-copy >/dev/null 2>&1; then
    command wl-copy "$@"
  elif [ -n "${DISPLAY:-}" ] && command -v xclip >/dev/null 2>&1; then
    command xclip -selection clipboard -in "$@"
  elif [ -n "${DISPLAY:-}" ] && command -v xsel >/dev/null 2>&1; then
    command xsel --clipboard --input "$@"
  else
    printf '%s\n' 'pbcopy: no usable clipboard backend (Wayland: wl-clipboard; X11: xclip or xsel)' >&2
    return 1
  fi
}

pbpaste() {
  if _clipboard_has_wayland && command -v wl-paste >/dev/null 2>&1; then
    command wl-paste --no-newline "$@"
  elif [ -n "${DISPLAY:-}" ] && command -v xclip >/dev/null 2>&1; then
    command xclip -selection clipboard -out "$@"
  elif [ -n "${DISPLAY:-}" ] && command -v xsel >/dev/null 2>&1; then
    command xsel --clipboard --output "$@"
  else
    printf '%s\n' 'pbpaste: no usable clipboard backend (Wayland: wl-clipboard; X11: xclip or xsel)' >&2
    return 1
  fi
}
