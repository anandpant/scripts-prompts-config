#!/usr/bin/env bash
set -euo pipefail

readonly BLESH_COMMIT="d69e4d549a1881a37300fe6b4a05478bd9157dfc"
readonly install_dir="${XDG_DATA_HOME:-$HOME/.local/share}/blesh"

if [ -r "$install_dir/.dgxspark-commit" ] && [ "$(cat "$install_dir/.dgxspark-commit")" = "$BLESH_COMMIT" ]; then
  printf 'ble.sh already installed at pinned commit %s.\n' "$BLESH_COMMIT"
  exit 0
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
git init -q "$tmp/ble.sh"
git -C "$tmp/ble.sh" remote add origin https://github.com/akinomyoga/ble.sh.git
git -C "$tmp/ble.sh" fetch --depth 1 origin "$BLESH_COMMIT"
git -C "$tmp/ble.sh" checkout -q --detach FETCH_HEAD
git -C "$tmp/ble.sh" submodule update --init --recursive --depth 1
make -s --no-print-directory -C "$tmp/ble.sh" install INSDIR="$install_dir" USE_DOC=no
printf '%s\n' "$BLESH_COMMIT" > "$install_dir/.dgxspark-commit"
printf 'Installed ble.sh for minimal command-validity highlighting.\n'
