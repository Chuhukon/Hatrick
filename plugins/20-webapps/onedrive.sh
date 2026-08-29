PLUGIN_DESC="OneDrive as a desktop app"
PLUGIN_REQUIRES="vivaldi"

WEBAPP_TITLE="OneDrive"
WEBAPP_URL="https://www.microsoft365.com/onedrive"

plugin_detect()  { webapp_detect; }
plugin_install() { webapp_apply; }
