PLUGIN_DESC=".NET SDK 8 (LTS)"

plugin_detect() { rpm -q dotnet-sdk-8.0 >/dev/null 2>&1; }

plugin_install() {
    # Older SDKs come from the Microsoft feed rather than Fedora's own.
    rpm -q packages-microsoft-prod >/dev/null 2>&1 ||
        sudo dnf install -y https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm

    sudo dnf install -y dotnet-sdk-8.0
}
