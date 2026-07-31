# DGX Bash UX: fish-like autosuggestions, completion menus, and command validity.
# Unknown command words stay bold red; every resolved command type overrides it.
ble-face -s syntax_command fg=red,bold
ble-face -s command_builtin_dot fg=green,bold
ble-face -s command_builtin fg=green
ble-face -s command_alias fg=teal,bold
ble-face -s command_function fg=99,bold
ble-face -s command_file fg=green,bold
ble-face -s command_keyword fg=blue,bold
ble-face -s command_directory fg=33,underline

# Use ble.sh's integrations rather than fzf's direct Readline bindings.
# bash-completion is loaded before this file by universal/qol-shell-tools.sh.
if command -v fzf >/dev/null 2>&1; then
  ble-import -d integration/fzf-completion
  ble-import -d integration/fzf-key-bindings
fi
