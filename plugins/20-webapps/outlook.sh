PLUGIN_DESC="Outlook mail and calendar as a desktop app"
PLUGIN_REQUIRES="vivaldi"
PLUGIN_DISABLED=1

WEBAPP_TITLE="Outlook"
WEBAPP_URL="https://outlook.office.com/mail/"

plugin_detect()  { webapp_detect; }
plugin_install() { webapp_apply; }
