PLUGIN_DESC="JetBrains Toolbox"

VERSION="3.7.2.87231"   # bump this line to move to a newer release

plugin_detect() { [ -x /opt/jetbrains-toolbox/bin/jetbrains-toolbox ]; }

plugin_install() {
    sudo rm -rf /opt/jetbrains-toolbox
    sudo mkdir -p /opt/jetbrains-toolbox

    # ~600 MB unpacked, and /tmp is a tmpfs on Fedora: unpack straight into
    # place rather than taking two bites out of RAM. --strip-components drops
    # the versioned top directory so /opt/jetbrains-toolbox stays stable.
    curl -fsSL "https://download.jetbrains.com/toolbox/jetbrains-toolbox-${VERSION}.tar.gz" |
        sudo tar -xzf - -C /opt/jetbrains-toolbox --strip-components=1

    # The launcher finds its own lib/ next to itself, so run it from bin/
    # instead of symlinking the binary out to another directory. Remove first:
    # the old symlink is still there on an upgrade and `tee` would write
    # straight through it into /opt.
    sudo rm -f /usr/local/bin/jetbrains-toolbox
    sudo tee /usr/local/bin/jetbrains-toolbox >/dev/null <<'EOF'
#!/bin/sh
cd /opt/jetbrains-toolbox/bin || exit 1
exec ./jetbrains-toolbox "$@"
EOF
    sudo chmod 0755 /usr/local/bin/jetbrains-toolbox

    echo "Run 'jetbrains-toolbox' to sign in and install your IDEs."
}
