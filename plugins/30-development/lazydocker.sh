# shellcheck shell=bash
# Hatrick plugin — lazydocker, built with Go into the user's GOPATH and then
# published system-wide. Built as the invoking user, so the module cache does
# not end up owned by root.

PLUGIN_NAME="lazydocker"
PLUGIN_DESC="lazydocker - terminal UI for Docker"
PLUGIN_GROUP="Development"
PLUGIN_DEFAULT=on
PLUGIN_REQUIRES="golang docker"

plugin_detect() {
    have lazydocker
}

plugin_install() {
    as_user env "GOPATH=${HATRICK_HOME}/go" \
        go install github.com/jesseduffield/lazydocker@latest

    local built="${HATRICK_HOME}/go/bin/lazydocker"
    [ -x "$built" ] || { log_error "go install did not produce $built"; return 1; }
    as_root install -m 0755 "$built" /usr/local/bin/lazydocker
}
