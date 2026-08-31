# lib/webapp.sh - the webapp engine.
#
# A webapp is a plugin that only *declares* a title and a URL and then calls
# webapp_detect / webapp_apply. Hatrick does not write a launcher: it adds the
# site to one Chromium policy file, and Vivaldi installs it as a real web app -
# its own window, its own icon in the dash, the same thing you get from
# "Install as app" in Vivaldi's menu. See "Writing a webapp" in README.md.
#
# The policy file is the one thing here that needs root, and it genuinely does:
# /etc/vivaldi/policies is where Chromium reads policy on Linux, and the only
# place it does. There is no per-user policy directory.

WEBAPP_POLICY="/etc/vivaldi/policies/managed/hatrick-webapps.json"

# webapp_detect - true when this URL is already in the policy. Cheap and
# sudo-free: the file is world readable and the menu re-reads it on every
# redraw. The quotes are part of the match, so one URL can never be found
# inside another it happens to be a prefix of.
webapp_detect() {
    [ -f "$WEBAPP_POLICY" ] || return 1
    grep -qF "\"${WEBAPP_URL}\"" "$WEBAPP_POLICY"
}

# webapp_apply - add this site to the list Vivaldi installs web apps from.
#
# Nothing is written to $HOME. Vivaldi reads the site's manifest and generates
# ~/.local/share/applications/vivaldi-<id>-Default.desktop itself, with
# Exec=... --app-id=<id>, StartupWMClass=crx_<id> and icons at every size.
# python3 rather than sed, because this is JSON that several plugins take
# turns editing; it is passed its arguments on the command line, so there is
# no need for sudo -E.
webapp_apply() {
    [ -n "${WEBAPP_TITLE:-}" ] && [ -n "${WEBAPP_URL:-}" ] ||
        { echo "  WEBAPP_TITLE and WEBAPP_URL are both required"; return 1; }
    command -v vivaldi-stable >/dev/null 2>&1 ||
        { echo "  vivaldi is not installed"; return 1; }
    command -v python3 >/dev/null 2>&1 ||
        { echo "  python3 is needed to edit the policy file"; return 1; }

    sudo mkdir -p "${WEBAPP_POLICY%/*}"
    sudo python3 -c '
import json, sys
path, url, name = sys.argv[1:4]
try:
    doc = json.load(open(path))
except (OSError, ValueError):
    doc = {}
apps = [a for a in doc.get("WebAppInstallForceList", []) if a.get("url") != url]
apps.append({"url": url, "default_launch_container": "window",
             "fallback_app_name": name})
doc["WebAppInstallForceList"] = sorted(apps, key=lambda a: a["url"])
with open(path, "w") as f:
    json.dump(doc, f, indent=2)
    f.write("\n")
' "$WEBAPP_POLICY" "$WEBAPP_URL" "$WEBAPP_TITLE"
    sudo chmod 0644 "$WEBAPP_POLICY"

    echo "  policy -> ${WEBAPP_POLICY}"
    echo "  Vivaldi installs it when it next starts, or within seconds if it is running."
}
