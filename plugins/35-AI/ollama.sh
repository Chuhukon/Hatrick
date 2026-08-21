PLUGIN_DESC="Ollama - run language models locally"

plugin_detect() { command -v ollama >/dev/null 2>&1; }

plugin_install() {
    # The script calls sudo itself for /usr/local, the ollama user and the
    # systemd service it enables.
    curl -fsSL https://ollama.com/install.sh | sh

    echo "Ollama serves on 127.0.0.1:11434. Fetch a model with 'ollama pull gemma3'."
}
