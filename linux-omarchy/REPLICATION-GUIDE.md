# Omarchy QoL Setup Replication Guide

This guide documents how to replicate the quality-of-life improvements made on top of base Omarchy.

---

## 0. Managed configuration

Omarchy dotfiles live in the private `shpitdev/my-nix` repository under `chezmoi/`. This repository keeps package setup and troubleshooting notes only; do not copy dotfiles from `linux-omarchy/configs/`.

Bootstrap a fresh machine:

```bash
sudo pacman -S --needed chezmoi
chezmoi init --apply git@github.com:shpitdev/my-nix.git
```

The my-nix checkout contains `.chezmoiroot`, so chezmoi uses its `chezmoi/` directory as the source state. On the existing Omarchy machine, the generated config points `sourceDir` at `~/Development/anandpant/my-nix`.

For durable changes, edit the my-nix source with `chezmoi edit`, or edit live and run `chezmoi re-add`; review `chezmoi diff`, apply, and ship the my-nix change.

---

## 1. Terminal QoL Tools

These tools provide autocomplete, better history, and smarter navigation.

### Install packages
```bash
sudo pacman -S zsh-autosuggestions zsh-fast-syntax-highlighting zsh-history-substring-search fzf eza bat zoxide atuin starship mise
```

### Add to ~/.zshrc
```bash
# Syntax highlighting, autosuggestions, history search
source /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

# fzf integration (Ctrl+R for history, Ctrl+T for files, Alt+C for cd)
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

# zoxide replaces cd (learns your frequently used directories)
eval "$(zoxide init zsh --cmd cd)"

# atuin for better shell history (syncs across machines)
eval "$(atuin init zsh)"

# starship prompt
eval "$(starship init zsh)"

# mise for language version management (replaces nvm, pyenv, etc.)
eval "$(mise activate zsh)"
```

### Launch desktop IDEs from persistent terminals

Herdr and other persistent terminal hosts can start before Hyprland and retain a shell environment without the active Wayland display. Source the shared launcher in both zsh and bash so `zed`, `zeditor`, `cursor`, `code`, `code-insiders`, and `subl` launch through the graphical UWSM session:

```bash
# ~/.zshrc and ~/.bashrc
if [ -f "$HOME/scripts-prompts-config/universal/uwsm-ide-shell-tools.sh" ]; then
  . "$HOME/scripts-prompts-config/universal/uwsm-ide-shell-tools.sh"
fi
```

### Match the macOS git prompt

Starship is managed by chezmoi:

```bash
chezmoi apply ~/.config/starship.toml
```

### What each tool does:
| Tool | Purpose |
|------|---------|
| `zsh-autosuggestions` | Ghost text suggestions as you type (accept with →) |
| `zsh-fast-syntax-highlighting` | Colors commands as you type (red = invalid, green = valid) |
| `zsh-history-substring-search` | Up/Down arrows search history by what you've typed |
| `fzf` | Fuzzy finder: Ctrl+R (history), Ctrl+T (files), Alt+C (cd) |
| `zoxide` | Smart `cd` that learns your frequent directories |
| `atuin` | Synced shell history with full-text search |
| `starship` | Fast, customizable prompt |
| `mise` | Polyglot version manager (node, python, go, etc.) |

---

## 2. Useful Aliases

Configure macOS-style `pbcopy`/`pbpaste` for both Bash and Zsh:

```bash
./linux-omarchy/scripts/setup-clipboard.sh
```

The setup detects the active display backend instead of assuming Wayland. It uses
`wl-clipboard` under Wayland and `xclip`/`xsel` under X11. On managed Ubuntu/Debian
hosts without sudo, it can extract the distro's `xclip` package into
`~/.local/bin`. The script installs shell hooks idempotently and verifies a
clipboard round trip.

Add the remaining aliases to `~/.zshrc`:

```bash
# Better ls (requires eza)
ls() { env -u NO_COLOR command eza -lh --group-directories-first --icons=auto "$@"; }
alias lsa='ls -a'
lt() { env -u NO_COLOR command eza --tree --level=2 --long --icons --git "$@"; }
alias lta='lt -a'
tree() { command tree -C "$@"; }

# Better cat (requires bat)
alias cat='bat'

# Fuzzy file finder with preview
alias ff="fzf --preview 'bat --style=numbers --color=always {}'"

# Quick navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Git shortcuts
alias g='git'
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'

# Docker
alias d='docker'

# Nvim: `n` opens current dir, `n file` opens file
n() { if [ "$#" -eq 0 ]; then nvim .; else nvim "$@"; fi; }

# Open files like macOS
open() { xdg-open "$@" >/dev/null 2>&1 & }

# Compression helpers
compress() { tar -czf "${1%/}.tar.gz" "${1%/}"; }
alias decompress="tar -xzf"

# Image/video processing (requires ffmpeg, imagemagick)
transcode-video-1080p() { ffmpeg -i $1 -vf scale=1920:1080 -c:v libx264 -preset fast -crf 23 -c:a copy ${1%.*}-1080p.mp4; }
transcode-video-4K() { ffmpeg -i $1 -c:v libx265 -preset slow -crf 24 -c:a aac -b:a 192k ${1%.*}-optimized.mp4; }
img2jpg() { img="$1"; shift; magick "$img" $@ -quality 95 -strip ${img%.*}-optimized.jpg; }
img2png() { img="$1"; shift; magick "$img" $@ -strip -define png:compression-filter=5 -define png:compression-level=9 -define png:compression-strategy=1 -define png:exclude-chunk=all "${img%.*}-optimized.png"; }
```

---

## 3. Mac-Style Keybindings (xremap)

Makes Cmd+C/V/A/Z etc. work system-wide like macOS.

### Install xremap
```bash
yay -S xremap-wlroots-bin
```

### Set up uinput permissions
```bash
# Create uinput rules
echo 'KERNEL=="uinput", GROUP="input", MODE="0660"' | sudo tee /etc/udev/rules.d/99-uinput.rules
echo 'uinput' | sudo tee /etc/modules-load.d/uinput.conf

# Add user to input group
sudo usermod -aG input $USER

# Reboot or reload
sudo modprobe uinput
sudo udevadm control --reload-rules
```

### Configure xremap

Apply the managed config from my-nix:

```bash
chezmoi apply ~/.config/xremap/config.yml
```

Notes on the current layout:
- Global Super→Ctrl mappings exclude Ghostty so Ghostty-only overrides always win.
- Ghostty-only overrides handle Super+A/C/V/W/D without clobbering terminal keys.
- Hyprland passthroughs preserve Super+Alt/Super+Ctrl combinations, including Super+Alt+D for voxtype dictation.
- Use `xremap-wlroots-bin`, not `xremap-hypr-bin`; the latter's Hyprland client is incompatible with newer Hyprland releases.
- Hyprland intercepts its own Super bindings before xremap. Remove a conflicting Hyprland binding in the managed Lua source when xremap should receive that key.
- If xremap starts before the compositor and logs `Could not find wayland compositor`, restart it after login with `systemctl --user restart xremap`.

### Autostart xremap (recommended: systemd --user)

```bash
chezmoi apply ~/.config/systemd/user/xremap.service
systemctl --user daemon-reload
systemctl --user enable --now xremap.service
```

If you need device names, use: `xremap --list-devices`


---

### Config sync checklist

- Review drift with `chezmoi diff`.
- Apply the source with `chezmoi apply`.
- If a deliberate live edit should become the source, run `chezmoi re-add <target>` from the my-nix checkout and ship that diff.
- Reload affected runtime surfaces: `hyprctl reload && hyprctl configerrors`, `systemctl --user restart xremap`, `tmux source-file ~/.tmux.conf`, or `herdr server reload-config`.

## 4. Hyprland Customizations

### Current Omarchy 4 / Hyprland Lua config

Omarchy 4 uses Lua for user Hyprland configuration. The current files are managed in `my-nix/chezmoi/dot_config/hypr/`.

```bash
chezmoi apply ~/.config/hypr
hyprctl reload
hyprctl configerrors
```

With the Lua parser, `hyprctl keyword monitor ...` fails with `keyword can't work with non-legacy parsers`. Use Lua `hl.monitor(...)` or `hyprctl eval ...` for monitor changes.

### Hyprland compatibility after an Omarchy update

Errors such as `config option <misc:new_window_takes_over_fullscreen> does not exist`, `invalid field`, or `keyword can't work with non-legacy parsers` usually indicate an outdated user override. Do not edit `/usr/share/omarchy`, `~/.config/omarchy`, or the `~/.local/share/omarchy` package link. Compare the managed override with the current APIs under `/usr/share/omarchy/default/hypr/`, update the my-nix chezmoi source, then apply and rerun `hyprctl configerrors`.

### Remap close window to Super+Q (so Cmd+W works in apps)

Add to `~/.config/hypr/bindings.conf`:
```bash
# Close window with Super+Q instead of Super+W
unbind = SUPER, W
bindd = SUPER, Q, Close window, killactive,
```

### Screenshot shortcuts (Ctrl+Shift+3/4/5)

Add to `~/.config/hypr/bindings.conf`:
```bash
bindd = CTRL SHIFT, 3, Screenshot fullscreen to clipboard, exec, omarchy-cmd-screenshot fullscreen clipboard
bindd = CTRL SHIFT, 4, Screenshot region to clipboard, exec, omarchy-cmd-screenshot region clipboard
bindd = CTRL SHIFT, 5, Screenshot smart to clipboard, exec, omarchy-cmd-screenshot smart clipboard
```

### Magnet-style window movement across monitors

Create `~/.local/bin/hypr-move-window`:
```bash
#!/bin/bash
# Move window in direction, crossing monitors when at edge

direction="$1"
window_info=$(hyprctl activewindow -j)
current_monitor_id=$(echo "$window_info" | jq -r '.monitor')
window_x=$(echo "$window_info" | jq -r '.at[0]')
window_y=$(echo "$window_info" | jq -r '.at[1]')

monitors=$(hyprctl monitors -j)
monitor_x=$(echo "$monitors" | jq -r ".[] | select(.id == $current_monitor_id) | .x")
monitor_y=$(echo "$monitors" | jq -r ".[] | select(.id == $current_monitor_id) | .y")

threshold=50

case "$direction" in
    l)
        if [ "$window_x" -lt "$threshold" ]; then
            target=$(echo "$monitors" | jq -r --argjson cx "$monitor_x" '[.[] | select(.x < $cx)] | sort_by(.x) | last | .name // empty')
            if [ -n "$target" ] && [ "$target" != "null" ]; then
                hyprctl dispatch movewindow mon:"$target"
                exit 0
            fi
        fi
        ;;
    r)
        hyprctl dispatch movewindoworgroup r
        sleep 0.05
        new_x=$(hyprctl activewindow -j | jq -r '.at[0]')
        if [ "$new_x" = "$window_x" ]; then
            target=$(echo "$monitors" | jq -r --argjson cx "$monitor_x" '[.[] | select(.x > $cx)] | sort_by(.x) | first | .name // empty')
            if [ -n "$target" ] && [ "$target" != "null" ]; then
                hyprctl dispatch movewindow mon:"$target"
                sleep 0.05
                hyprctl dispatch movewindoworgroup l
            fi
        fi
        exit 0
        ;;
    u)
        if [ "$window_y" -lt "$threshold" ]; then
            target=$(echo "$monitors" | jq -r --argjson cy "$monitor_y" '[.[] | select(.y < $cy)] | sort_by(.y) | last | .name // empty')
            if [ -n "$target" ] && [ "$target" != "null" ]; then
                hyprctl dispatch movewindow mon:"$target"
                exit 0
            fi
        fi
        ;;
    d)
        hyprctl dispatch movewindoworgroup d
        sleep 0.05
        new_y=$(hyprctl activewindow -j | jq -r '.at[1]')
        if [ "$new_y" = "$window_y" ]; then
            target=$(echo "$monitors" | jq -r --argjson cy "$monitor_y" '[.[] | select(.y > $cy)] | sort_by(.y) | first | .name // empty')
            if [ -n "$target" ] && [ "$target" != "null" ]; then
                hyprctl dispatch movewindow mon:"$target"
            fi
        fi
        exit 0
        ;;
esac

hyprctl dispatch movewindoworgroup "$direction"
```

Make it executable and add bindings:
```bash
chmod +x ~/.local/bin/hypr-move-window
```

Add to `~/.config/hypr/bindings.conf`:
```bash
bindd = SUPER CTRL, LEFT, Move window left, exec, ~/.local/bin/hypr-move-window l
bindd = SUPER CTRL, RIGHT, Move window right, exec, ~/.local/bin/hypr-move-window r
bindd = SUPER CTRL, UP, Move window up, exec, ~/.local/bin/hypr-move-window u
bindd = SUPER CTRL, DOWN, Move window down, exec, ~/.local/bin/hypr-move-window d
```

### Screen Zoom (Magnification)

Hyprland has built-in cursor zoom for accessibility. Add to `~/.config/hypr/looknfeel.conf`:
```bash
cursor {
    no_hardware_cursors = true  # Required for zoom to work
    zoom_rigid = true           # Zoom follows cursor rigidly
}
```

In Omarchy 4, add this to `~/.config/hypr/bindings.lua`:
```lua
hl.unbind("SUPER + mouse_down")
hl.unbind("SUPER + mouse_up")

hl.config({
  binds = {
    scroll_event_delay = 50,
  },
})

local function set_cursor_zoom(zoom)
  if zoom < 1 then
    zoom = 1
  end
  hl.config({ cursor = { zoom_factor = zoom } })
end

local function multiply_cursor_zoom(multiplier)
  set_cursor_zoom((hl.get_config("cursor.zoom_factor") or 1) * multiplier)
end

o.bind("SUPER + CTRL + equal", "Zoom in", function()
  multiply_cursor_zoom(1.1)
end, { repeating = true })
o.bind("SUPER + CTRL + minus", "Zoom out", function()
  multiply_cursor_zoom(0.9)
end, { repeating = true })
o.bind("SUPER + CTRL + KP_ADD", "Zoom in", function()
  multiply_cursor_zoom(1.1)
end, { repeating = true })
o.bind("SUPER + CTRL + KP_SUBTRACT", "Zoom out", function()
  multiply_cursor_zoom(0.9)
end, { repeating = true })
o.bind("SUPER + CTRL + mouse_down", "Zoom in", function()
  multiply_cursor_zoom(1.1)
end)
o.bind("SUPER + CTRL + mouse_up", "Zoom out", function()
  multiply_cursor_zoom(0.9)
end)
o.bind("SUPER + CTRL + 0", "Zoom reset", function()
  set_cursor_zoom(1)
end)
```

For old `.conf` configs, the previous `hyprctl keyword cursor:zoom_factor ...` commands were valid. They are not valid with the Lua parser.

**Notes:**
- Zoom only magnifies (values > 1.0). Values below 1.0 have no visual effect.
- Mouse scroll uses SUPER+CTRL so zoom stays separate from workspace switching.
- If you do not want workspace switching on `SUPER+scroll`, keep the two `unbind = SUPER, mouse_*` lines above.

### Monitor Scale Presets (4K displays)

For quick switching between display scales. Fractional scales must divide evenly into resolution.

For 3840x2160, valid scales include:
| Scale | Effective Resolution |
|-------|---------------------|
| 1.5 | 2560x1440 |
| 1.6 | 2400x1350 |
| 1.666667 | 2304x1296 |
| 1.875 | 2048x1152 |
| 2.0 | 1920x1080 |

Add to `~/.config/hypr/bindings.lua` (uses F13/F14/F15 on Keychron keyboards):
```lua
local function set_dp1_scale(scale)
  hl.monitor({ output = "DP-1", mode = "preferred", position = "auto", scale = scale })
end

o.bind("XF86Tools", "DP-1 scale 1.666667", function()
  set_dp1_scale(1.666667)
end)
o.bind("XF86Launch5", "DP-1 scale 1.875", function()
  set_dp1_scale(1.875)
end)
o.bind("XF86Launch6", "DP-1 scale 2", function()
  set_dp1_scale(2)
end)

o.bind("F13", "DP-1 scale 1.666667", function()
  set_dp1_scale(1.666667)
end)
o.bind("F14", "DP-1 scale 1.875", function()
  set_dp1_scale(1.875)
end)
o.bind("F15", "DP-1 scale 2", function()
  set_dp1_scale(2)
end)
```

**Note:** Keychron F13/F14/F15 send `XF86Tools`, `XF86Launch5`, `XF86Launch6`. Use `wev -f wl_keyboard:key` to find your keyboard's actual keycodes.

### Theme Accents (Active Border Gradient)

Set a soft sage gradient for active borders in `~/.config/omarchy/current/theme/hyprland.conf`:
```bash
$activeBorderColor = rgba(0a100bee) rgba(8aab96ee) 45deg

general {
    col.active_border = $activeBorderColor
}

group {
    col.border_active = $activeBorderColor
}
```

### Scratchpad Window Management

Omarchy includes a scratchpad (special workspace) with default bindings:
- `Super+S` - Toggle scratchpad visibility
- `Super+Alt+S` - Move window to scratchpad

To add a toggle that moves windows to/from scratchpad:

Create `~/.local/bin/toggle-scratchpad-window`:
```bash
#!/bin/bash
# Toggle window between scratchpad and previous workspace

workspace=$(hyprctl activewindow -j | jq -r '.workspace.name')

if [[ "$workspace" == "special:scratchpad" ]]; then
    # Move back to the most recent regular workspace
    hyprctl dispatch movetoworkspace e+0
else
    # Move to scratchpad
    hyprctl dispatch movetoworkspacesilent special:scratchpad
fi
```

Make it executable:
```bash
chmod +x ~/.local/bin/toggle-scratchpad-window
```

Add to `~/.config/hypr/hyprland.conf`:
```bash
# Toggle window to/from scratchpad
bind = SUPER SHIFT, S, exec, ~/.local/bin/toggle-scratchpad-window
```

Add visual indicator (pastel sage border) for scratchpad windows in `~/.config/hypr/looknfeel.conf`:
```bash
# Pastel sage border for scratchpad windows
windowrule = border_color rgb(8aab96) rgb(8aab96), match:workspace special:scratchpad
windowrule = border_size 2, match:workspace special:scratchpad
```

### Dropdown Terminal (Alacritty, special workspace)

Create `~/.local/bin/toggle-dropdown-terminal`:
```bash
#!/bin/bash
# Toggle dropdown terminal - spawns if not running, toggles visibility if running

if hyprctl clients -j | jq -e '.[] | select(.class == "alacritty-dropdown")' > /dev/null 2>&1; then
    hyprctl dispatch togglespecialworkspace dropdown
else
    uwsm-app -- alacritty --class alacritty-dropdown &
    sleep 0.3
    hyprctl dispatch togglespecialworkspace dropdown
fi
```

Make it executable:
```bash
chmod +x ~/.local/bin/toggle-dropdown-terminal
```

Add window rules to `~/.config/hypr/hyprland.conf`:
```bash
# Window rules for dropdown terminal
windowrulev2 = float, class:^(alacritty-dropdown)$
windowrulev2 = size 100% 45%, class:^(alacritty-dropdown)$
windowrulev2 = move 0 0, class:^(alacritty-dropdown)$
windowrulev2 = workspace special:dropdown silent, class:^(alacritty-dropdown)$
windowrulev2 = animation slideIn, class:^(alacritty-dropdown)$
```

**Note:** No global keybinding is set by default to avoid conflicts. Bind it manually if desired.

---

## 5. Voice Dictation (voxtype + local Parakeet)

`voxtype` provides local streaming dictation with the Parakeet unified English 0.6b model. Its config and user service are managed by chezmoi:

```bash
chezmoi apply ~/.config/voxtype/config.toml ~/.config/systemd/user/voxtype.service
voxtype setup model
systemctl --user daemon-reload
systemctl --user enable --now voxtype.service
```

Omarchy keeps Super+Ctrl+X for toggle dictation and F9 for push-to-talk; the managed override also binds Super+Alt+D to `voxtype record toggle`.

With `streaming = true`, `streaming_chunk_secs`, `streaming_left_context_secs`, and `streaming_right_context_secs` must each be a multiple of 0.08 seconds. Debug with `journalctl --user -u voxtype -f`.

## 6. Alacritty Terminal Config

Alacritty is managed by chezmoi:

```bash
chezmoi apply ~/.config/alacritty/alacritty.toml
```

The managed file uses the Omarchy theme, launches tmux, preserves Insert copy/paste controls, and sends Shift+Return as CSI-u.

---

## 7. Kitty Terminal Config

Apply the managed kitty config and themes:

```bash
chezmoi apply ~/.config/kitty
```

Notes:
- Default theme is Tokyo Night Storm (included via `include themes/tokyo-night-storm.conf`).
- Aether theme available as an alternative (change the include line in kitty.conf).
- Uses `clear_all_shortcuts yes` and defines only the bindings needed (Ctrl-based, matching Linux muscle memory).
- `shift+enter` sends ESC+CR for Claude Code accept behavior.
- Reload with `Ctrl+Shift+F5` or restart kitty.

---

## 8. Ghostty Terminal Config

Apply the managed Ghostty config:

```bash
chezmoi apply ~/.config/ghostty/config
```

Notes:
- Uses the Omarchy theme file via `config-file = ?"~/.config/omarchy/current/theme/ghostty.conf"`.
- Super-based bindings remain in Ghostty, but Ghostty-specific xremap overrides map Super+A/C/V/W/D to Ctrl+Shift+… in Ghostty.
- Ctrl+Shift+W is bound to `close_surface` so Super+W closes the current split (not the entire window).
- Bell attention and command-finish notifications are disabled to avoid terminal focus-steal on CLI completion.

## 9. tmux Config

Apply the managed tmux config and reload it:

```bash
chezmoi apply ~/.tmux.conf
tmux source-file ~/.tmux.conf
```

Notes:
- `bell-action none` plus disabled activity/silence actions prevent tmux from marking the terminal urgent when a CLI emits BEL.

### Herdr installation and service upgrades

Run `bash ~/scripts-prompts-config/linux-omarchy/scripts/install-herdr.sh` to install
Herdr 0.9.0 from its checksum-verified Linux release. The installer leaves running
servers and panes untouched and installs the `ExitType=cgroup` systemd drop-in.
This lets native live handoff replace the server without systemd killing its agents.

Before replacing a running server, capture its pane/process list and session
snapshot. Use native live handoff when supported, then verify the server version
and that agent process IDs survived. An ordinary `systemctl --user restart
herdr.service` stops pane processes; recover their saved native sessions if a
restart is necessary. Keep desktop-session environment drop-ins in place.

### Herdr keybindings

Apply the managed Herdr config and reload it:

```bash
chezmoi apply ~/.config/herdr/config.toml
herdr server reload-config
```

The bindings mirror the terminal muscle memory: `Ctrl+Space` is the prefix, then `g` enters persistent navigation, `d` splits right, `Shift+D` splits down, `t` opens a tab, and `w` closes the current pane.

---

## 10. Zed Editor Configuration

Zed keybindings and settings are managed by chezmoi:

```bash
chezmoi apply ~/.config/zed/keymap.json ~/.config/zed/settings.json
```

The managed keymap provides macOS-style Super shortcuts while preserving terminal copy/paste behavior. Keep authentication and API keys out of the tracked settings.

---

## 11. VS Code Keybindings

Create `~/.config/Code/User/keybindings.json`:
```json
[
    {
        "key": "shift+enter",
        "command": "workbench.action.terminal.sendSequence",
        "args": { "text": "\u001b\r" },
        "when": "terminalFocus"
    }
]
```

---

## 12. Llama.cpp Serve Helper (Parakeet v3 CPU/GPU Toggle)

When serving a llama model, temporarily switch Parakeet v3 to CPU to free VRAM, then restore GPU on exit.

`/home/anandpant/llama.cpp/serve.sh`:
```bash
# Switch parakeet to CPU mode to free up vRAM for llama
systemctl --user stop parakeet-tdt-0.6b-v3.service 2>/dev/null
PARAKEET_USE_CPU=1 systemctl --user set-environment PARAKEET_USE_CPU=1
systemctl --user start parakeet-tdt-0.6b-v3.service

# Restore parakeet to GPU mode on exit
cleanup() {
    systemctl --user stop parakeet-tdt-0.6b-v3.service 2>/dev/null
    systemctl --user unset-environment PARAKEET_USE_CPU
    systemctl --user start parakeet-tdt-0.6b-v3.service
}
trap cleanup EXIT INT TERM
```

---

## 13. Neovim (LazyVim)

The setup is mostly default LazyVim. Only customization:

Edit `~/.config/nvim/lua/config/options.lua`:
```lua
vim.opt.relativenumber = false
```

---

## Summary Checklist

- [ ] Install chezmoi and run `chezmoi init --apply git@github.com:shpitdev/my-nix.git`
- [ ] Review `chezmoi diff`, apply the managed dotfiles, and verify Hyprland, xremap, voxtype, terminals, and agent instructions
- [ ] Install terminal tools: `zsh-autosuggestions`, `zsh-fast-syntax-highlighting`, `zsh-history-substring-search`, `fzf`, `eza`, `bat`, `zoxide`, `atuin`, `starship`, `mise`
- [ ] Install `xremap-wlroots-bin` and set up uinput permissions
- [ ] Keep Zed credentials local; never add them to the managed settings
- [ ] Configure VS Code shift+enter binding
- [ ] Verify llama.cpp serve helper toggles Parakeet v3 CPU/GPU correctly
