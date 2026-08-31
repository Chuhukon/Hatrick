PLUGIN_DESC="GitHub Copilot CLI - GitHub's coding agent in the terminal"

VERSION="latest"   # latest, prerelease, or a fixed version like 0.0.369

plugin_detect() { [ -x "$HOME/.local/bin/copilot" ]; }

plugin_install() {
    # Without sudo the script installs to $PREFIX/bin, so ~/.local/bin here.
    curl -fsSL https://gh.io/copilot-install | VERSION="$VERSION" bash

    echo "Run 'copilot' in a project and use /login; a Copilot subscription is required."
}
