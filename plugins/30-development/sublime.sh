PLUGIN_DESC="Sublime Text + Sublime Merge"

plugin_detect() { rpm -q sublime-text >/dev/null 2>&1 && rpm -q sublime-merge >/dev/null 2>&1; }

plugin_install() {
    sudo rpm --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
    sudo dnf config-manager addrepo --overwrite \
        --from-repofile=https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo
    sudo dnf install -y sublime-text sublime-merge
}
