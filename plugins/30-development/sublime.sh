# shellcheck shell=bash
# Hatrick plugin — Sublime Text and Sublime Merge from Sublime HQ's repository.

PLUGIN_NAME="sublime"
PLUGIN_DESC="Sublime Text + Sublime Merge"
PLUGIN_GROUP="Development"
PLUGIN_DEFAULT=on

SUBLIME_KEY="https://download.sublimetext.com/sublimehq-rpm-pub.gpg"
SUBLIME_REPO="https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo"

plugin_detect() {
    pkg_installed sublime-text && pkg_installed sublime-merge
}

plugin_install() {
    import_rpm_key "$SUBLIME_KEY"
    add_repofile "$SUBLIME_REPO"
    pkg_install sublime-text sublime-merge
}
