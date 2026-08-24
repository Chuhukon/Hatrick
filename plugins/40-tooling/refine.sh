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

    # Needs a running GNOME Shell to talk to, so never fatal.
    gnome-extensions enable appindicatorsupport@rgcjonas.gmail.com ||
        echo "Could not enable AppIndicator support; do it in the Extensions app."

    echo "Enable the installed extensions in the Extensions app."
}
