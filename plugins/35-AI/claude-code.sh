PLUGIN_DESC="Claude Code - Anthropic's coding agent in the terminal"

CHANNEL="stable"   # stable, latest, or a fixed version like 2.0.14

plugin_detect() { [ -x "$HOME/.local/bin/claude" ]; }

plugin_install() {
    # Lands in ~/.local/bin and updates itself from there, so no sudo. The
    # installer refuses to run under sudo for exactly that reason.
    curl -fsSL https://claude.ai/install.sh | bash -s "$CHANNEL"

    echo "Run 'claude' in a project to sign in."
}
