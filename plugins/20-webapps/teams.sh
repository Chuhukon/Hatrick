PLUGIN_DESC="Microsoft Teams as a desktop app"
PLUGIN_REQUIRES="vivaldi"

WEBAPP_TITLE="Microsoft Teams"
WEBAPP_URL="https://teams.microsoft.com/"

plugin_detect()  { webapp_detect; }
plugin_install() { webapp_apply; }
