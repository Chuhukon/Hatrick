PLUGIN_DESC="Pinta image editor (Flatpak)"

# https://www.pinta-project.com - upstream points Linux users at the Flatpak;
# Fedora's own pinta package trails it by a major version.

plugin_detect() { flatpak info com.github.PintaProject.Pinta >/dev/null 2>&1; }

plugin_install() {
    # A vanilla Fedora has flatpak but no flathub remote, so add it first.
    flatpak remote-add --if-not-exists --user \
        flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    flatpak install --user -y flathub com.github.PintaProject.Pinta
}
