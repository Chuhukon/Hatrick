# shellcheck shell=bash
# Hatrick plugin — point the GNOME desktop at the fonts we just installed.
# This is applied to the invoking user's session, not root's.

PLUGIN_NAME="gnome-font-settings"
PLUGIN_DESC="Use Mona Sans / JetBrains Mono in GNOME"
PLUGIN_GROUP="Fonts"
PLUGIN_DEFAULT=on
PLUGIN_REQUIRES="jetbrains-mono mona-sans"

GNOME_FONT_UI="Mona Sans 10"
GNOME_FONT_MONO="JetBrains Mono NL Light 11"
GNOME_FONT_DOC="JetBrains Mono NL Light 12"

plugin_detect() {
    [ "$(as_user gsettings get org.gnome.desktop.interface font-name 2>/dev/null)" = "'${GNOME_FONT_UI}'" ]
}

plugin_install() {
    if ! is_gnome; then
        log_warn "no GNOME session detected; font settings not applied"
        return 0
    fi
    gsettings_set org.gnome.desktop.interface font-name          "$GNOME_FONT_UI"
    gsettings_set org.gnome.desktop.interface monospace-font-name "$GNOME_FONT_MONO"
    gsettings_set org.gnome.desktop.interface document-font-name  "$GNOME_FONT_DOC"
}
