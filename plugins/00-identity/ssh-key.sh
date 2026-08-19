PLUGIN_DESC="SSH key (ed25519)"

KEY="$HOME/.ssh/id_ed25519"

plugin_detect() { [ -f "$KEY" ]; }

plugin_install() {
    local email

    # Reset before read: under `set -e` an unguarded read would stop the plugin.
    printf '  Email for the key: '
    email=""; read -r email || true

    # ssh-keygen only creates ~/.ssh when it uses its own default path, not
    # when -f names one, so make it here. No -N, so ssh-keygen asks for the
    # passphrase itself, on /dev/tty.
    mkdir -p -m 700 "$HOME/.ssh"
    ssh-keygen -t ed25519 -C "$email" -f "$KEY"

    echo
    echo "  Add this to GitHub -> Settings -> SSH and GPG keys:"
    cat "$KEY.pub"
}
