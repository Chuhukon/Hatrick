import { describe, expect, it } from "bun:test";
import { findHatrickRoot, formatCategory, formatPluginId, discoverPluginFiles, probePlugin, loadAllPlugins } from "./pluginLoader";

describe("pluginLoader", () => {
  it("resolves the hatrick root directory", () => {
    const root = findHatrickRoot();
    expect(root).toBeDefined();
    expect(root.length).toBeGreaterThan(0);
  });

  it("formats categories and plugin IDs accurately", () => {
    expect(formatCategory("00-system")).toBe("System");
    expect(formatCategory("20-webapps")).toBe("Webapps");
    expect(formatCategory("50-theme")).toBe("Theme");

    expect(formatPluginId("00-ssh-key.sh")).toBe("ssh-key");
    expect(formatPluginId("docker.sh")).toBe("docker");
    expect(formatPluginId("10-vscode.sh")).toBe("vscode");
  });

  it("discovers all plugin files from plugins/*/*.sh", () => {
    const root = findHatrickRoot();
    const files = discoverPluginFiles(root);
    expect(files.length).toBeGreaterThan(20);

    const docker = files.find((f) => f.id === "docker");
    expect(docker).toBeDefined();
    expect(docker?.category).toBe("Development");
  });

  it("correctly probes real plugin metadata, requirements, and detect hooks", async () => {
    const root = findHatrickRoot();
    const plugins = await loadAllPlugins(root);
    expect(plugins.length).toBeGreaterThan(20);

    // Verify docker plugin
    const docker = plugins.find((p) => p.id === "docker");
    expect(docker).toBeDefined();
    expect(docker?.description).toBe("Docker Engine, CLI and compose");
    expect(docker?.supportsDetect).toBe(true);
    expect(docker?.supportsRemove).toBe(false);

    // Verify webapp plugin with requirements
    const whatsapp = plugins.find((p) => p.id === "whatsapp");
    expect(whatsapp).toBeDefined();
    expect(whatsapp?.requires).toContain("vivaldi");
    expect(whatsapp?.category).toBe("Webapps");
  });
});
