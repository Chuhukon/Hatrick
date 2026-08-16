# shellcheck shell=bash
# Hatrick plugin — .NET SDK 10. Fedora ships this one in its own repositories.

PLUGIN_NAME="dotnet-10"
PLUGIN_DESC=".NET SDK 10"
PLUGIN_GROUP="Development"
PLUGIN_DEFAULT=on

PLUGIN_VERSION="10.0"

plugin_detect() {
    pkg_installed "dotnet-sdk-${PLUGIN_VERSION}"
}

plugin_install() {
    pkg_install "dotnet-sdk-${PLUGIN_VERSION}"
}
