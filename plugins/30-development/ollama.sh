PLUGIN_DESC="Ollama - run LLMs locally (localhost:11434)"

plugin_detect() { command -v ollama >/dev/null 2>&1; }

plugin_install() {
    # Ollama's own installer: it detects the GPU, adds the ollama user and
    # enables the systemd service. It calls sudo itself, so do not run it as root.
    curl -fsSL https://ollama.com/install.sh | sh

    echo "Pull a model with 'ollama pull gpt-oss:20b', then 'ollama run gpt-oss:20b'."
}
