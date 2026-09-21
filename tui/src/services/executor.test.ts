import { describe, expect, it } from "bun:test";
import { buildExecutionSteps } from "./executor";
import type { PluginActionType, PluginMetadata } from "../types";

const mockPlugins: PluginMetadata[] = [
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
    id: "vscode",
    name: "vscode",
    category: "Development",
    categoryRaw: "30-development",
    filePath: "/plugins/30-development/vscode.sh",
    description: "Visual Studio Code",
    requires: [],
    disabled: false,
    isInstalled: false,
    supportsDetect: true,
    supportsUpdate: true,
    supportsRemove: true,
  },
];

describe("executor", () => {
  it("builds system preparation and plugin execution steps in order", () => {
    const staged = new Map<string, PluginActionType>([
      ["docker", "update"],
      ["vscode", "install"],
    ]);

    const { steps, commands } = buildExecutionSteps(staged, mockPlugins);

    // System steps first
    expect(steps.length).toBe(4);
    expect(steps[0].id).toBe("prepare-system");
    expect(steps[1].id).toBe("setup-fonts");
    expect(steps[2].id).toBe("plugin-docker");
    expect(steps[3].id).toBe("plugin-vscode");

    // Command verification
    expect(commands[0].args).toEqual(["prepare-system"]);
    expect(commands[1].args).toEqual(["setup-fonts"]);
    expect(commands[2].args).toEqual(["run-plugin", "docker", "update"]);
    expect(commands[3].args).toEqual(["run-plugin", "vscode", "install"]);
  });

  it("omits plugins marked with action none", () => {
    const staged = new Map<string, PluginActionType>([
      ["docker", "none"],
    ]);

    const { steps } = buildExecutionSteps(staged, mockPlugins);
    expect(steps.length).toBe(2);
    expect(steps[0].id).toBe("prepare-system");
    expect(steps[1].id).toBe("setup-fonts");
  });
});
