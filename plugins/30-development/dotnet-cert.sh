PLUGIN_DESC="Dotnet Cert"
# Opt-in: dotnet-8 and dotnet-10 already trust the dev cert on install.
# No plugin_detect on purpose: when ticked it always runs, it is idempotent.
PLUGIN_DISABLED=1

plugin_install() {
    dotnet_trust_dev_cert
}
