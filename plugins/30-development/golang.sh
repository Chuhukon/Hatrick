PLUGIN_DESC="Go toolchain"

plugin_detect() { command -v go >/dev/null 2>&1; }

plugin_install() {
    sudo dnf install -y golang
}
