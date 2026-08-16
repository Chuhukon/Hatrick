# shellcheck shell=bash
# Hatrick plugin — the Go toolchain. Also the build dependency for lazydocker.

PLUGIN_NAME="golang"
PLUGIN_DESC="Go toolchain"
PLUGIN_GROUP="Development"
PLUGIN_DEFAULT=on

plugin_detect() {
    have go
}

plugin_install() {
    pkg_install golang
}
