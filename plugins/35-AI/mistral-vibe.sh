PLUGIN_DESC="Mistral Vibe - Mistral's coding agent in the terminal"

plugin_detect() { command -v vibe >/dev/null 2>&1; }

plugin_install() {
    # Installs uv into ~/.local/bin when it is missing, then runs
    # `uv tool install mistral-vibe`, which puts vibe there as well. No sudo,
    # and running it again upgrades rather than reinstalls.
    curl -LsSf https://mistral.ai/vibe/install.sh | bash

    echo "Run 'vibe' in a project to sign in, or paste an API key from https://chat.mistral.ai/code/extensions."
}
