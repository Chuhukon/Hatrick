PLUGIN_DESC="Vivaldi browser (set as default)"

plugin_detect() { rpm -q vivaldi-stable >/dev/null 2>&1; }

plugin_install() {
    sudo dnf config-manager addrepo --overwrite \
        --from-repofile=https://repo.vivaldi.com/stable/vivaldi-fedora.repo
    sudo dnf install -y vivaldi-stable

    # Only works inside a graphical session; not worth failing the run over.
    xdg-settings set default-web-browser vivaldi-stable.desktop 2>/dev/null || true
}
