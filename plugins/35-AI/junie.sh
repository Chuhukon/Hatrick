PLUGIN_DESC="Junie - JetBrains coding agent in the terminal"

plugin_detect() { [ -x "$HOME/.local/bin/junie" ]; }

plugin_install() {
    # The installer unpacks a zip and stops early when unzip is missing.
    sudo dnf install -y unzip

    # Versions live in ~/.local/share/junie with a shim in ~/.local/bin; the
    # shim upgrades itself, so this never needs sudo.
    curl -fsSL https://junie.jetbrains.com/install.sh | bash

    echo "Run 'junie' in a project to sign in with your JetBrains account."
}
