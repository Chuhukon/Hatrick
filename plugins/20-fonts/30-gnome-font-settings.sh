PLUGIN_DESC="Use Mona Sans / JetBrains Mono in GNOME"
PLUGIN_REQUIRES="jetbrains-mono mona-sans"

# No sudo anywhere here: these settings belong to your session, not root's.

plugin_detect() {
    [ "$(gsettings get org.gnome.desktop.interface font-name 2>/dev/null)" = "'Mona Sans 10'" ]
}

plugin_install() {
    gsettings set org.gnome.desktop.interface font-name 'Mona Sans 10'
    gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrains Mono NL Light 11'
    gsettings set org.gnome.desktop.interface document-font-name 'JetBrains Mono NL Light 12'
}
