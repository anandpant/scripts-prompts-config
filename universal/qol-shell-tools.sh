# Guarded interactive-shell initialization shared by Linux Bash and Zsh.
[ -r "$HOME/.atuin/bin/env" ] && . "$HOME/.atuin/bin/env"

if [ -n "${BASH_VERSION:-}" ]; then
  command -v mise >/dev/null 2>&1 && eval "$(mise activate bash)"
  command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"
  command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init bash --cmd cd)"
  if command -v fzf >/dev/null 2>&1 && fzf --bash >/dev/null 2>&1; then
    eval "$(fzf --bash)"
  fi
  command -v atuin >/dev/null 2>&1 && eval "$(atuin init bash)"
elif [ -n "${ZSH_VERSION:-}" ]; then
  command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh)"
  command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"
  command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh --cmd cd)"
  if command -v fzf >/dev/null 2>&1 && fzf --zsh >/dev/null 2>&1; then
    eval "$(fzf --zsh)"
  fi
  command -v atuin >/dev/null 2>&1 && eval "$(atuin init zsh)"
fi
