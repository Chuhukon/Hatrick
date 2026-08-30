PLUGIN_DESC="OneDrive as a desktop app"
PLUGIN_REQUIRES="vivaldi"
PLUGIN_DISABLED=1

WEBAPP_TITLE="OneDrive"
WEBAPP_URL="https://www.microsoft365.com/onedrive"

plugin_detect()  { webapp_detect; }
plugin_install() { webapp_apply; }
