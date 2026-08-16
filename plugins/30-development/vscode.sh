# shellcheck shell=bash
# Hatrick plugin — Visual Studio Code. Microsoft publishes no .repo file for
# the VS Code feed, so Hatrick writes one.

PLUGIN_NAME="vscode"
PLUGIN_DESC="Visual Studio Code"
PLUGIN_GROUP="Development"
PLUGIN_DEFAULT=on

VSCODE_KEY="https://packages.microsoft.com/keys/microsoft.asc"

plugin_detect() {
    pkg_installed code
}

plugin_install() {
    import_rpm_key "$VSCODE_KEY"
    write_repofile vscode "[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
gpgcheck=1
gpgkey=${VSCODE_KEY}"
    pkg_install code
}
