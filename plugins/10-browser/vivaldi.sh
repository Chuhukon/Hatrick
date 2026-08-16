# shellcheck shell=bash
# Hatrick plugin — Vivaldi, installed from Vivaldi's own repository.

PLUGIN_NAME="vivaldi"
PLUGIN_DESC="Vivaldi browser (set as default)"
PLUGIN_GROUP="Browser"
PLUGIN_DEFAULT=on

plugin_detect() {
    pkg_installed vivaldi-stable
}

plugin_install() {
    add_repofile https://repo.vivaldi.com/stable/vivaldi-fedora.repo
    pkg_install vivaldi-stable
}

plugin_postinstall() {
    # Only meaningful inside a graphical session; never fail the run over it.
    as_user xdg-settings set default-web-browser vivaldi-stable.desktop 2>/dev/null || true
}
