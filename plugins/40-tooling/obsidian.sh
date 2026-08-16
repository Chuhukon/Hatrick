# shellcheck shell=bash
# Hatrick plugin — Obsidian via Flatpak, into the user's own flatpak scope.

PLUGIN_NAME="obsidian"
PLUGIN_DESC="Obsidian (Flatpak)"
PLUGIN_GROUP="Tooling"
PLUGIN_DEFAULT=on

OBSIDIAN_APP_ID="md.obsidian.Obsidian"

plugin_detect() {
    as_user flatpak info "$OBSIDIAN_APP_ID" >/dev/null 2>&1
}

plugin_install() {
    # ensure_flathub matters here: a vanilla Fedora has flatpak but no flathub
    # remote, so a bare 'flatpak install flathub ...' fails.
    flatpak_install "$OBSIDIAN_APP_ID"
}
