# shellcheck shell=bash
# Hatrick plugin — .NET SDK 8 (LTS). Comes from the Microsoft package feed,
# which older SDKs need on Fedora.

PLUGIN_NAME="dotnet-8"
PLUGIN_DESC=".NET SDK 8 (LTS)"
PLUGIN_GROUP="Development"
PLUGIN_DEFAULT=on

PLUGIN_VERSION="8.0"
MICROSOFT_PROD_RPM="https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm"

plugin_detect() {
    pkg_installed "dotnet-sdk-${PLUGIN_VERSION}"
}

plugin_install() {
    if ! pkg_installed packages-microsoft-prod; then
        add_repo_rpm "$MICROSOFT_PROD_RPM"
    fi
    pkg_install "dotnet-sdk-${PLUGIN_VERSION}"
}
