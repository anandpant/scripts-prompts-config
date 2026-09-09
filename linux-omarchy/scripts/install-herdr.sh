#!/usr/bin/env bash
set -euo pipefail

# Install the reviewed release. Server replacement is a separate, deliberate step.
version=0.9.0
sha256=4fa1a01158dd8043da92d31b270780b0dcc10603038d9b61cac4d81ab63fb71f
if [[ "$(uname -s):$(uname -m)" != Linux:x86_64 ]]; then
  printf 'This installer supports Linux x86_64 only.\n' >&2
  exit 1
fi
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
mkdir -p "$HOME/.local/bin"
download=$(mktemp "$HOME/.local/bin/.herdr-install.XXXXXX")
trap 'rm -f "$download"' EXIT
curl --fail --location --silent --show-error \
  "https://github.com/herdrdev/herdr/releases/download/v$version/herdr-linux-x86_64" \
  -o "$download"
printf '%s  %s\n' "$sha256" "$download" | sha256sum -c -
chmod 755 "$download"
[[ "$("$download" --version)" == "herdr $version" ]]
# Rename atomically; never truncate a binary used by a running server.
mv "$download" "$HOME/.local/bin/herdr"
mkdir -p "$HOME/.config/systemd/user/herdr.service.d"
cp "$repo_root/linux-omarchy/configs/herdr.service.d/handoff.conf" \
  "$HOME/.config/systemd/user/herdr.service.d/handoff.conf"
systemctl --user daemon-reload
printf 'Installed Herdr %s. Existing server and panes are still running.\n' "$version"
