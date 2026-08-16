# shellcheck shell=bash
# Hatrick plugin — JetBrains Toolbox. Extracted to a stable path under /opt and
# symlinked; it is not auto-launched, the user starts it when they want to.

PLUGIN_NAME="jetbrains-toolbox"
PLUGIN_DESC="JetBrains Toolbox"
PLUGIN_GROUP="Development"
PLUGIN_DEFAULT=on

# Bump this one line to move to a newer release.
PLUGIN_VERSION="3.6.4.86641"

TOOLBOX_URL="https://download.jetbrains.com/toolbox/jetbrains-toolbox-${PLUGIN_VERSION}.tar.gz"
TOOLBOX_DIR="/opt/jetbrains-toolbox"

plugin_detect() {
    [ -x "${TOOLBOX_DIR}/bin/jetbrains-toolbox" ]
}

plugin_install() {
    local archive="${HATRICK_TMP}/jetbrains-toolbox.tar.gz"
    local staging="${HATRICK_TMP}/jetbrains-toolbox"

    fetch "$TOOLBOX_URL" "$archive"
    mkdir -p "$staging"
    # Strip the versioned top-level directory so the install path stays stable.
    tar -xzf "$archive" -C "$staging" --strip-components=1

    as_root rm -rf "$TOOLBOX_DIR"
    as_root mkdir -p "$TOOLBOX_DIR"
    as_root cp -a "$staging/." "$TOOLBOX_DIR/"
    as_root ln -sf "${TOOLBOX_DIR}/bin/jetbrains-toolbox" /usr/local/bin/jetbrains-toolbox

    plugin_note "Run 'jetbrains-toolbox' once to sign in and install your IDEs."
}
