PLUGIN_DESC="Tactile - tile windows on a grid with the keyboard"

UUID="tactile@lundal.io"
VERSION_TAG="75027"   # Tactile 38, for GNOME Shell 45 and newer

plugin_detect() {
    gnome-extensions list 2>/dev/null | grep -qx "$UUID"
}

plugin_install() {
    # Not in the Fedora repositories, so take the zip from extensions.gnome.org.
    # The version tag picks the release; bump it when a newer one is out.
    local zip="${HATRICK_TMP:-/tmp}/tactile.zip"
    curl -fsSL -o "$zip" \
        "https://extensions.gnome.org/download-extension/${UUID}.shell-extension.zip?version_tag=${VERSION_TAG}"

    # Installs into ~/.local/share/gnome-shell/extensions, so no sudo.
    gnome-extensions install --force "$zip"

    # The running shell does not know it yet, so this goes through gsettings.
    gnome_extension_enable "$UUID"

    echo "Log out and back in, then press Super-T to show the grid."
}
