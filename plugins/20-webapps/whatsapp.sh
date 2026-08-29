PLUGIN_DESC="WhatsApp Web as a desktop app"
PLUGIN_REQUIRES="vivaldi"

WEBAPP_TITLE="WhatsApp"
WEBAPP_URL="https://web.whatsapp.com/"

plugin_detect()  { webapp_detect; }
plugin_install() { webapp_apply; }
