PLUGIN_DESC="ROCm (AMD GPU compute runtime and tools)"
PLUGIN_DISABLED=1

# Fedora 44 ships ROCm 7.1 in its own repositories, and AMD's repo.radeon.com
# has no Fedora build at all, so this adds no repo and pins no version: dnf
# already has the right one. Only the runtime half is installed; the headers
# and hipcc are `sudo dnf install rocm-devel`, and the `rocm` metapackage pulls
# the full 3 GB of compute libraries.

plugin_detect() {
    rpm -q rocminfo >/dev/null 2>&1 &&
        { ! command -v ollama >/dev/null 2>&1 ||
          [ -f /etc/systemd/system/ollama.service.d/rocm.conf ]; }
}

plugin_install() {
    # amdgpu publishes every compute-capable agent under /sys/class/kfd, and the
    # node's gfx_target_version is the ISA ROCm has to have been built for:
    # 110500 is gfx1150. The CPU is an agent too and reports 0, so a nonzero one
    # is the GPU. Same topology rocminfo reads, minus the 400 MB to run it.
    local props line v=""
    for props in /sys/class/kfd/kfd/topology/nodes/*/properties; do
        [ -r "$props" ] || continue
        line=$(grep -m1 '^gfx_target_version' "$props") || continue
        if [ "${line#gfx_target_version }" != 0 ]; then
            v="${line#gfx_target_version }"
            break
        fi
    done

    if [ -z "$v" ]; then
        echo "No AMD compute device: the kernel reports no GPU under /sys/class/kfd."
        echo "Either there is no AMD GPU here, or amdgpu did not bind it."
        return 1
    fi

    local gfx
    gfx=$(printf 'gfx%d%x%x' "$((v / 10000))" "$((v / 100 % 100))" "$((v % 100))")

    # ROCm 7 dropped everything before Vega. Those cards still drive a display
    # and still do OpenCL through Mesa; they just cannot do this.
    if [ "$v" -lt 90000 ]; then
        echo "This GPU is $gfx, and ROCm 7 needs gfx900 (Vega) or newer."
        return 1
    fi

    echo "Found an AMD GPU: $gfx."

    # rocm-hip and rocm-opencl are the two runtimes an application links
    # against; rocminfo, rocm-smi and rocm-clinfo are how you see the card.
    # About 400 MB with everything they pull in.
    sudo dnf install -y rocminfo rocm-smi rocm-hip rocm-opencl rocm-clinfo

    # Being new enough is not the same as being one of the targets the libraries
    # were actually built for, and rocminfo is the first thing that can say so.
    rocminfo >/dev/null 2>&1 ||
        echo "rocminfo cannot open the device; $gfx may need HSA_OVERRIDE_GFX_VERSION set to a target that is built."

    echo "rocm-smi watches the card, rocm-clinfo lists the OpenCL side."

    # Ollama ships its own ROCm and finds the card with it, but skips an
    # integrated GPU unless told otherwise, and would rather use Vulkan. A
    # drop-in survives Ollama's installer rewriting ollama.service on upgrade.
    if command -v ollama >/dev/null 2>&1; then
        sudo mkdir -p /etc/systemd/system/ollama.service.d
        printf '[Service]\nEnvironment="OLLAMA_IGPU_ENABLE=1"\nEnvironment="OLLAMA_VULKAN=0"\n' |
            sudo tee /etc/systemd/system/ollama.service.d/rocm.conf >/dev/null
        sudo systemctl daemon-reload
        if systemctl is-active --quiet ollama; then
            sudo systemctl restart ollama
        fi
        echo "Ollama now runs models on $gfx through ROCm; check with 'ollama ps'."
    fi
}
