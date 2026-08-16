# shellcheck shell=bash
# Hatrick plugin — bring the system up to date before anything else is added.

PLUGIN_NAME="system-update"
PLUGIN_DESC="Update all existing packages"
PLUGIN_GROUP="Base"
PLUGIN_DEFAULT=on
PLUGIN_MANDATORY=yes

plugin_install() {
    pkg_update
}
