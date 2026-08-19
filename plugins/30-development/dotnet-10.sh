PLUGIN_DESC=".NET SDK 10"

plugin_detect() { rpm -q dotnet-sdk-10.0 >/dev/null 2>&1; }

plugin_install() {
    sudo dnf install -y dotnet-sdk-10.0
}
