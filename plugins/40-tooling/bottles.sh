PLUGIN_DESC="Bottles (run Windows apps)"

# https://usebottles.com - upstream only supports the Flatpak; it ships its own
# wine runners inside the sandbox, so nothing needs installing on the host.

plugin_detect() { flatpak info com.usebottles.bottles >/dev/null 2>&1; }

plugin_install() {
    # A vanilla Fedora has flatpak but no flathub remote, so add it first.
    flatpak remote-add --if-not-exists --user \
        flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    flatpak install --user -y flathub com.usebottles.bottles

    echo "Bottles keeps its bottles in ~/.var/app/com.usebottles.bottles."
}
