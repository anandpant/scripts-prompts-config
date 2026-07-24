#!/usr/bin/env sh
# Launch desktop IDEs through the graphical systemd/UWSM session.
# Persistent terminal hosts such as Herdr can predate Hyprland and therefore
# lack DISPLAY/WAYLAND_DISPLAY even though the user manager has the right env.

_uwsm_ide_launch() {
  _uwsm_ide_binary=$1
  shift

  case "${1:-}" in
    -h|--help|-v|--version)
      "$_uwsm_ide_binary" "$@"
      return
      ;;
  esac

  if command -v uwsm >/dev/null 2>&1 && systemctl --user --quiet is-active graphical-session.target 2>/dev/null; then
    uwsm app -t service -- "$_uwsm_ide_binary" "$@"
  else
    "$_uwsm_ide_binary" "$@"
  fi
}

zed() {
  _uwsm_ide_launch "$HOME/.local/zed-preview.app/bin/zed" "$@"
}

zeditor() {
  _uwsm_ide_launch /usr/bin/zeditor "$@"
}

cursor() {
  _uwsm_ide_launch "$HOME/.local/bin/cursor" "$@"
}

code() {
  _uwsm_ide_launch /usr/bin/code-insiders "$@"
}

code-insiders() {
  _uwsm_ide_launch /usr/bin/code-insiders "$@"
}

subl() {
  _uwsm_ide_launch /usr/bin/subl "$@"
}
