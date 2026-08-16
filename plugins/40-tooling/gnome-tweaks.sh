# shellcheck shell=bash
# Hatrick plugin — GNOME Tweaks and extension management.

PLUGIN_NAME="gnome-tweaks"
PLUGIN_DESC="GNOME Tweaks + extension manager"
PLUGIN_GROUP="Tooling"
PLUGIN_DEFAULT=on

plugin_detect() {
    pkg_installed gnome-tweaks && pkg_installed gnome-extensions-app
}

plugin_install() {
    if ! is_gnome; then
        log_warn "no GNOME session detected; installing anyway"
    fi
    pkg_install gnome-tweaks gnome-extensions-app
    # Extensions people reach for first on a fresh GNOME.
    pkg_install gnome-shell-extension-appindicator \
                gnome-shell-extension-dash-to-dock || \
        log_warn "some GNOME extensions were unavailable in the repositories"

    plugin_note "Enable installed GNOME extensions in the Extensions app."
}
