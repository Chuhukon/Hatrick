PLUGIN_DESC="Microsoft Teams as a desktop app"
PLUGIN_REQUIRES="vivaldi"
PLUGIN_DISABLED=1

WEBAPP_TITLE="Microsoft Teams"
WEBAPP_URL="https://teams.microsoft.com/"

plugin_detect()  { webapp_detect; }
plugin_install() { webapp_apply; }
