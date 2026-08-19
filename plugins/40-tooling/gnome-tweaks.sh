PLUGIN_DESC="GNOME Tweaks + extension manager"

plugin_detect() { rpm -q gnome-tweaks >/dev/null 2>&1 && rpm -q gnome-extensions-app >/dev/null 2>&1; }

plugin_install() {
    sudo dnf install -y gnome-tweaks gnome-extensions-app

    # Extensions people reach for first on a fresh GNOME; not fatal if missing.
    sudo dnf install -y gnome-shell-extension-appindicator \
                        gnome-shell-extension-dash-to-dock ||
        echo "Some GNOME extensions were not available in the repositories."

    gnome-extensions enable appindicatorsupport@rgcjonas.gmail.com

    echo "Enable the installed extensions in the Extensions app."
}
