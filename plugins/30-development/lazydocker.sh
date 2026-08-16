PLUGIN_DESC="lazydocker - terminal UI for Docker"
PLUGIN_REQUIRES="golang docker"

plugin_detect() { command -v lazydocker >/dev/null 2>&1; }

plugin_install() {
    # Built as you, so the Go module cache does not end up owned by root.
    go install github.com/jesseduffield/lazydocker@latest
    sudo install -m 0755 "$HOME/go/bin/lazydocker" /usr/local/bin/lazydocker
}
