PLUGIN_DESC="SSH key (ed25519)"

KEY="$HOME/.ssh/id_ed25519"

plugin_detect() { [ -f "$KEY" ]; }

plugin_install() {
    # Hatrick asks for $HATRICK_EMAIL before the run starts, so nothing has to
    # stop and ask here. Empty is fine; the key simply gets no comment.

    # ssh-keygen only creates ~/.ssh when it uses its own default path, not
    # when -f names one, so make it here. No -N, so ssh-keygen asks for the
    # passphrase itself, on /dev/tty.
    mkdir -p -m 700 "$HOME/.ssh"
    ssh-keygen -t ed25519 -C "${HATRICK_EMAIL:-}" -f "$KEY"

    echo
    echo "  Add this to GitHub -> Settings -> SSH and GPG keys:"
    cat "$KEY.pub"
}
