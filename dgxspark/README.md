# DGX Spark

Minimal host-specific setup for the Ubuntu/ARM64 DGX Spark. Portable settings
stay in `universal/`; this directory contains only DGX-specific documentation
and entry points.

## Host differences

- Ubuntu 24.04 on ARM64 (`aarch64`), not Arch/Omarchy.
- GNOME currently runs under X11, so clipboard commands need `xclip`, not
  Wayland's `wl-copy`.
- The managed user does not have passwordless sudo. The shared clipboard setup
  can extract Ubuntu's architecture-matched `xclip` package into
  `~/.local/bin` without duplicating or vendoring the binary in this repo.
- Hyprland, Waybar, xremap, and Omarchy desktop configs do not apply to this
  host unless its desktop session is changed intentionally.

## Apply the shared setup

```bash
./dgxspark/scripts/apply-configs.sh
```

This installs architecture-matched CLI releases through `mise`, applies the
shared Starship, Claude/Pi, Codex, OpenCode, Cursor, Neovim, and tmux configs,
sets Linux pnpm security defaults, and preserves replaced files as timestamped
backups. It invokes the clipboard setup below as part of the run.

### Clipboard only

```bash
./dgxspark/scripts/setup-clipboard.sh
```

`dgxspark/scripts/setup-clipboard.sh` is a symlink to the shared implementation
at `universal/setup-clipboard.sh`. It detects X11 versus Wayland, installs the
appropriate backend, hooks both Bash and Zsh, and verifies copy/paste.

Do not copy whole Omarchy or macOS config trees here. Add only a small override
when architecture, distro packaging, display server, or hardware genuinely
requires different behavior; otherwise link to or invoke the shared source.
