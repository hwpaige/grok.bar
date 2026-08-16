#!/usr/bin/env bash
# Install PATH helpers and, from a local checkout, place the plugin folder.
# omarchy plugin add never runs this file.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ID="io.github.hwpaige.grok-bar"
PLUGIN_DEST="${HOME}/.config/omarchy/plugins/${PLUGIN_ID}"
OLD_IDS=(harrison.grok grok.bar)

mkdir -p "${HOME}/.local/bin" "${HOME}/.config/foot" "${HOME}/.config/omarchy/plugins"

install -m 755 "$ROOT/bin/omarchy-grok-sessions" "${HOME}/.local/bin/omarchy-grok-sessions"
install -m 755 "$ROOT/bin/omarchy-launch-grok" "${HOME}/.local/bin/omarchy-launch-grok"
install -m 755 "$ROOT/bin/omarchy-grok-term" "${HOME}/.local/bin/omarchy-grok-term"
install -m 755 "$ROOT/bin/grok" "${HOME}/.local/bin/grok"
install -m 755 "$ROOT/bin/omarchy-launch-tui" "${HOME}/.local/bin/omarchy-launch-tui"
install -m 644 "$ROOT/foot/grok.ini" "${HOME}/.config/foot/grok.ini"

place_plugin_folder() {
  local dest_real=""
  local root_real old_dest old_real
  root_real="$(realpath "$ROOT")"

  for old in "${OLD_IDS[@]}"; do
    old_dest="${HOME}/.config/omarchy/plugins/${old}"
    if [[ -L "$old_dest" ]]; then
      old_real="$(realpath "$old_dest" 2>/dev/null || true)"
      if [[ "$old_real" == "$root_real" ]]; then
        rm -f "$old_dest"
      fi
    fi
  done

  if [[ -L "$PLUGIN_DEST" ]]; then
    ln -sfn "$ROOT" "$PLUGIN_DEST"
    return
  fi

  if [[ -d "$PLUGIN_DEST" ]]; then
    dest_real="$(realpath "$PLUGIN_DEST")"
    if [[ "$dest_real" == "$root_real" ]]; then
      return
    fi
    echo "Plugin already installed at $PLUGIN_DEST; leaving that checkout in place." >&2
    return
  fi

  ln -sfn "$ROOT" "$PLUGIN_DEST"
}

place_plugin_folder

if command -v omarchy >/dev/null 2>&1; then
  omarchy plugin validate "$ROOT"
  omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
  for old in "${OLD_IDS[@]}"; do
    omarchy plugin disable "$old" >/dev/null 2>&1 || true
  done
  omarchy bar put "$PLUGIN_ID" --after omarchy.clock >/dev/null 2>&1 \
    || omarchy bar put "$PLUGIN_ID" --section center >/dev/null 2>&1 \
    || omarchy plugin enable "$PLUGIN_ID" --section center >/dev/null 2>&1 \
    || true
fi

echo "Installed helpers for $PLUGIN_ID"
echo "Left-click the Grok mark (next to the clock) for sessions; right-click for a new window."
