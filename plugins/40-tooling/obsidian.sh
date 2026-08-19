PLUGIN_DESC="Obsidian (Flatpak)"

plugin_detect() { flatpak info md.obsidian.Obsidian >/dev/null 2>&1; }

plugin_install() {
    # A vanilla Fedora has flatpak but no flathub remote, so add it first.
    flatpak remote-add --if-not-exists --user \
        flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    flatpak install --user -y flathub md.obsidian.Obsidian
}
