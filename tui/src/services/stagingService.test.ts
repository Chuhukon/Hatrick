import { describe, expect, it } from "bun:test";
import { stagePluginAction, togglePluginAction, stageAllMissing, clearAllStaged } from "./stagingService";
import type { PluginMetadata } from "../types";

const mockPlugins: PluginMetadata[] = [
  {
    id: "vivaldi",
    name: "vivaldi",
    category: "Browser",
    categoryRaw: "10-browser",
    filePath: "/plugins/10-browser/vivaldi.sh",
    description: "Vivaldi browser",
    requires: [],
    disabled: false,
    isInstalled: false,
    supportsDetect: true,
    supportsUpdate: false,
    supportsRemove: false,
  },
  {
    id: "whatsapp",
    name: "whatsapp",
    category: "Webapps",
    categoryRaw: "20-webapps",
    filePath: "/plugins/20-webapps/whatsapp.sh",
    description: "WhatsApp Web",
    requires: ["vivaldi"],
    disabled: false,
    isInstalled: false,
    supportsDetect: true,
    supportsUpdate: false,
    supportsRemove: false,
  },
  {
    id: "docker",
    name: "docker",
    category: "Development",
    categoryRaw: "30-development",
    filePath: "/plugins/30-development/docker.sh",
    description: "Docker Engine",
    requires: [],
    disabled: false,
    isInstalled: true,
    supportsDetect: true,
    supportsUpdate: false,
    supportsRemove: false,
  },
  {
    id: "cleanable",
    name: "cleanable",
    category: "Development",
    categoryRaw: "30-development",
    filePath: "/plugins/30-development/cleanable.sh",
    description: "Cleanable tool",
    requires: [],
    disabled: false,
    isInstalled: true,
    supportsDetect: true,
    supportsUpdate: true,
    supportsRemove: true,
  },
];

describe("stagingService", () => {
  it("stages and unstages plugins correctly", () => {
    let staged = new Map();
    const docker = mockPlugins.find((p) => p.id === "docker")!;

    const r1 = stagePluginAction(staged, docker, "install", mockPlugins);
    expect(r1.nextStaged.get("docker")).toBe("install");

    const r2 = stagePluginAction(r1.nextStaged, docker, "none", mockPlugins);
    expect(r2.nextStaged.has("docker")).toBe(false);
  });

  it("automatically stages uninstalled dependencies when a plugin is staged", () => {
    const staged = new Map();
    const whatsapp = mockPlugins.find((p) => p.id === "whatsapp")!;

    const res = stagePluginAction(staged, whatsapp, "install", mockPlugins);
    expect(res.nextStaged.get("whatsapp")).toBe("install");
    expect(res.nextStaged.get("vivaldi")).toBe("install");
    expect(res.autoStagedDeps).toContain("vivaldi");
  });

  it("prevents staging remove when plugin does not declare plugin_remove", () => {
    const staged = new Map();
    const docker = mockPlugins.find((p) => p.id === "docker")!;

    const res = stagePluginAction(staged, docker, "remove", mockPlugins);
    expect(res.warning).toBeDefined();
    expect(res.nextStaged.has("docker")).toBe(false);
  });

  it("permits staging remove when plugin declares plugin_remove", () => {
    const staged = new Map();
    const cleanable = mockPlugins.find((p) => p.id === "cleanable")!;

    const res = stagePluginAction(staged, cleanable, "remove", mockPlugins);
    expect(res.warning).toBeUndefined();
    expect(res.nextStaged.get("cleanable")).toBe("remove");
  });

  it("toggles action based on current state", () => {
    let staged = new Map();
    const whatsapp = mockPlugins.find((p) => p.id === "whatsapp")!;

    const r1 = togglePluginAction(staged, whatsapp, mockPlugins);
    expect(r1.nextStaged.get("whatsapp")).toBe("install");

    const r2 = togglePluginAction(r1.nextStaged, whatsapp, mockPlugins);
    expect(r2.nextStaged.has("whatsapp")).toBe(false);
  });
});
