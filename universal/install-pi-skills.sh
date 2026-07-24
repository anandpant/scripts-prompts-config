#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PI_SKILLS_DIR="${PI_SKILLS_DIR:-$HOME/.pi/agent/skills}"
readonly HERDR_SOURCE="$SCRIPT_DIR/.pi/agent/skills/herdr-pi"
readonly HERDR_TARGET="$PI_SKILLS_DIR/herdr-pi"
readonly LEGACY_HERDR_TARGET="$PI_SKILLS_DIR/herdr"

mkdir -p "$PI_SKILLS_DIR"

# Pi discovers ~/.agents/skills natively. Old bridge links make it discover the
# same skill twice, so remove only links that resolve into that shared directory.
while IFS= read -r -d '' link; do
  target="$(realpath "$link")"
  case "$target" in
    "$HOME/.agents/skills/"*)
      printf 'Removing redundant shared-skill link: %s\n' "$link"
      rm "$link"
      ;;
  esac
done < <(find "$PI_SKILLS_DIR" -mindepth 1 -maxdepth 1 -type l -print0)

# A Pi-specific skill cannot retain the shared `herdr` name: Pi also scans
# ~/.agents/skills/herdr and warns on duplicate names. Refuse to discard a
# local directory automatically; it may contain intentional edits.
if [[ -e "$LEGACY_HERDR_TARGET" || -L "$LEGACY_HERDR_TARGET" ]]; then
  printf 'Legacy Pi Herdr skill still exists: %s\n' "$LEGACY_HERDR_TARGET" >&2
  printf 'Review/remove it, then rerun this installer. The replacement is named herdr-pi.\n' >&2
  exit 1
fi

if [[ -e "$HERDR_TARGET" || -L "$HERDR_TARGET" ]]; then
  if [[ -L "$HERDR_TARGET" && "$(realpath "$HERDR_TARGET")" == "$(realpath "$HERDR_SOURCE")" ]]; then
    printf 'Pi-specific Herdr skill already linked: %s\n' "$HERDR_TARGET"
    exit 0
  fi
  printf 'Refusing to replace existing path: %s\n' "$HERDR_TARGET" >&2
  exit 1
fi

ln -s "$HERDR_SOURCE" "$HERDR_TARGET"
printf 'Linked Pi-specific Herdr skill: %s -> %s\n' "$HERDR_TARGET" "$HERDR_SOURCE"
