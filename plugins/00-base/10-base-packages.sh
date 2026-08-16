# shellcheck shell=bash
# Hatrick plugin — the tools every other plugin assumes are present.

PLUGIN_NAME="base-packages"
PLUGIN_DESC="Base dependencies (curl, git, unzip, fontconfig, flatpak, ...)"
PLUGIN_GROUP="Base"
PLUGIN_DEFAULT=on
PLUGIN_MANDATORY=yes
PLUGIN_REQUIRES="system-update"

plugin_install() {
    pkg_install \
        wget curl gpg gnupg2 ca-certificates \
        fontconfig unzip tar git flatpak dnf-plugins-core
}
