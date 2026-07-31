#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ts="$(date +%Y%m%d-%H%M%S)"

backup_install() {
  local src="$1" dst="$2" mode="${3:-644}"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && ! cmp -s "$src" "$dst"; then
    cp -a "$dst" "$dst.bak-$ts"
  fi
  install -m "$mode" "$src" "$dst"
}

add_shell_source() {
  local rc="$1" label="$2" relative="$3" line
  line="[ -f \"\$HOME/scripts-prompts-config/$relative\" ] && . \"\$HOME/scripts-prompts-config/$relative\""
  touch "$rc"
  if ! grep -Fq "$relative" "$rc"; then
    printf '\n# %s\n%s\n' "$label" "$line" >> "$rc"
  fi
}

"$repo_root/dgxspark/scripts/setup-clipboard.sh"
"$repo_root/dgxspark/scripts/install-qol-tools.sh"
"$repo_root/dgxspark/scripts/install-blesh.sh"

backup_install "$repo_root/linux-omarchy/configs/starship.toml" "$HOME/.config/starship.toml"
"$repo_root/universal/install-agent-reasoning-shortcuts.sh"

codex_merged="$(mktemp)"
cp "$repo_root/universal/.codex/config.toml" "$codex_merged"
printf '\n[projects."%s"]\ntrust_level = "trusted"\n' "$HOME" >> "$codex_merged"
backup_install "$codex_merged" "$HOME/.codex/config.toml"
rm -f "$codex_merged"

backup_install "$repo_root/universal/.config/opencode/opencode.jsonc" "$HOME/.config/opencode/opencode.jsonc"
backup_install "$repo_root/universal/.config/opencode/tui.jsonc" "$HOME/.config/opencode/tui.jsonc"
backup_install "$repo_root/universal/.config/opencode/tui-plugins/variant-reverse.js" "$HOME/.config/opencode/tui-plugins/variant-reverse.js"
backup_install "$repo_root/universal/.cursor/settings.json" "$HOME/.cursor/settings.json"
backup_install "$repo_root/dgxspark/configs/pnpm-config.yaml" "$HOME/.config/pnpm/config.yaml"
backup_install "$repo_root/dgxspark/configs/blesh-init.sh" "$HOME/.config/blesh/init.sh"
backup_install "$repo_root/linux-omarchy/configs/tmux.conf" "$HOME/.tmux.conf"

mkdir -p "$HOME/.config/nvim"
cp -a "$repo_root/universal/.config/nvim/." "$HOME/.config/nvim/"

for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  add_shell_source "$rc" 'Shared guarded CLI initialization' 'universal/qol-shell-tools.sh'
  add_shell_source "$rc" 'Shared Codex feature-drift helper' 'universal/codex-shell-tools.sh'
done

if ! grep -Fq '/blesh/ble.sh' "$HOME/.bashrc"; then
  printf '\n# Minimal Bash command-validity highlighting\n[[ $- == *i* && -r "${XDG_DATA_HOME:-$HOME/.local/share}/blesh/ble.sh" ]] && source -- "${XDG_DATA_HOME:-$HOME/.local/share}/blesh/ble.sh"\n' >> "$HOME/.bashrc"
fi

if [ ! -d "$HOME/.tmux/plugins/tpm/.git" ]; then
  mkdir -p "$HOME/.tmux/plugins"
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi
"$HOME/.tmux/plugins/tpm/bin/install_plugins"

printf 'DGX Spark shared configuration applied. Backups use suffix .bak-%s.\n' "$ts"
