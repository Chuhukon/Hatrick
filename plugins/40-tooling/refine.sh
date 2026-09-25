PLUGIN_DESC="Refine + Extensions manager (Flatpak)"

plugin_detect() {
    flatpak info page.tesk.Refine >/dev/null 2>&1 &&
        flatpak info org.gnome.Extensions >/dev/null 2>&1
}

plugin_install() {
    # A vanilla Fedora has flatpak but no flathub remote, so add it first.
    flatpak remote-add --if-not-exists --user \
        flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    flatpak install --user -y flathub page.tesk.Refine org.gnome.Extensions

    # Shell extensions run inside gnome-shell, so they come from Fedora, not
    # Flathub. Not fatal if a release has not built them yet.
    sudo dnf install -y gnome-shell-extension-appindicator \
                        gnome-shell-extension-dash-to-dock ||
        echo "Some GNOME extensions were not available in the repositories."

    # The running shell does not know them yet, so this goes through gsettings.
    gnome_extension_enable appindicatorsupport@rgcjonas.gmail.com \
                           dash-to-dock@micxgx.gmail.com

    echo "Log out and back in for the extensions to load."
}
