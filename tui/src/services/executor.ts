import { spawn, type ChildProcess } from "child_process";
import { join } from "path";
import type { ExecutionStep, PluginActionType, PluginMetadata } from "../types";
import { findHatrickRoot } from "./pluginLoader";

export interface ExecutionPlan {
  steps: ExecutionStep[];
}

export interface StepCommand {
  stepId: string;
  command: string;
  args: string[];
}

export interface ExecutorCallbacks {
  onStepChange: (step: ExecutionStep) => void;
  onLog: (line: string) => void;
  onComplete: (summary: {
    total: number;
    success: number;
    failed: number;
    elapsedSeconds: number;
  }) => void;
}

/**
 * Generate execution steps from staged plugin actions.
 */
export function buildExecutionSteps(
  stagedActions: Map<string, PluginActionType>,
  allPlugins: PluginMetadata[]
): { steps: ExecutionStep[]; commands: StepCommand[] } {
  const hatrickRoot = findHatrickRoot();
  const hatrickBin = join(hatrickRoot, "hatrick.sh");

  const steps: ExecutionStep[] = [
    {
      id: "prepare-system",
      title: "System: Base packages and DNF updates",
      status: "pending",
    },
    {
      id: "setup-fonts",
      title: "System: Core fonts and fontconfig rendering",
      status: "pending",
    },
  ];

  const commands: StepCommand[] = [
    {
      stepId: "prepare-system",
      command: hatrickBin,
      args: ["prepare-system"],
    },
    {
      stepId: "setup-fonts",
      command: hatrickBin,
      args: ["setup-fonts"],
    },
  ];

  for (const [pluginId, action] of stagedActions.entries()) {
    if (action === "none") continue;
    const plugin = allPlugins.find((p) => p.id === pluginId);
    const desc = plugin ? plugin.description : pluginId;
    const actionLabel = action.toUpperCase();

    const stepId = `plugin-${pluginId}`;
    steps.push({
      id: stepId,
      title: `${actionLabel}: ${pluginId} (${desc})`,
      status: "pending",
    });

    commands.push({
      stepId,
      command: hatrickBin,
      args: ["run-plugin", pluginId, action],
    });
  }

  return { steps, commands };
}

/**
 * Orchestrates sequential execution of commands and streams logs.
 */
export class ActionExecutor {
  private activeProcess: ChildProcess | null = null;
  private keepaliveTimer: ReturnType<typeof setInterval> | null = null;
  private aborted = false;

  public async run(
    steps: ExecutionStep[],
    commands: StepCommand[],
    callbacks: ExecutorCallbacks
  ): Promise<void> {
    const startTime = Date.now();
    let successCount = 0;
    let failedCount = 0;

    // Start sudo keepalive
    this.startSudoKeepalive();

    for (let i = 0; i < commands.length; i++) {
      if (this.aborted) break;

      const cmd = commands[i];
      const step = steps.find((s) => s.id === cmd.stepId);
      if (!step) continue;

      step.status = "running";
      callbacks.onStepChange({ ...step });
      callbacks.onLog(`\n==> [${i + 1}/${commands.length}] ${step.title}\n`);

      const exitCode = await this.executeCommand(cmd.command, cmd.args, callbacks.onLog);

      if (exitCode === 0) {
        step.status = "success";
        successCount++;
        callbacks.onLog(`[SUCCESS] ${step.title}\n`);
      } else {
        step.status = "failed";
        step.error = `Exited with code ${exitCode}`;
        failedCount++;
        callbacks.onLog(`[FAILED] ${step.title} (Exit Code: ${exitCode})\n`);
      }

      callbacks.onStepChange({ ...step });
    }

    this.stopSudoKeepalive();

    const elapsedSeconds = Math.round((Date.now() - startTime) / 1000);
    callbacks.onComplete({
      total: commands.length,
      success: successCount,
      failed: failedCount,
      elapsedSeconds,
    });
  }

  public abort(): void {
    this.aborted = true;
    if (this.activeProcess) {
      try {
        this.activeProcess.kill("SIGTERM");
      } catch {
        // Ignore kill errors
      }
    }
    this.stopSudoKeepalive();
  }

  private executeCommand(
    command: string,
    args: string[],
    onLog: (line: string) => void
  ): Promise<number> {
    return new Promise((resolve) => {
      try {
        const child = spawn(command, args, {
          env: { ...process.env, NO_COLOR: "1" },
        });

        this.activeProcess = child;

        child.stdout?.on("data", (chunk: Buffer) => {
          onLog(chunk.toString());
        });

        child.stderr?.on("data", (chunk: Buffer) => {
          onLog(chunk.toString());
        });

        child.on("close", (code) => {
          this.activeProcess = null;
          resolve(code ?? 1);
        });

        child.on("error", (err) => {
          onLog(`Error launching ${command}: ${err.message}\n`);
          this.activeProcess = null;
          resolve(1);
        });
      } catch (err) {
        onLog(`Exception: ${String(err)}\n`);
        resolve(1);
      }
    });
  }

  private startSudoKeepalive(): void {
    // Sudo keepalive loop every 45s
    this.keepaliveTimer = setInterval(() => {
      try {
        const p = spawn("sudo", ["-n", "true"]);
        p.on("error", () => {});
      } catch {
        // Ignore sudo keepalive error
      }
    }, 45000);
  }

  private stopSudoKeepalive(): void {
    if (this.keepaliveTimer) {
      clearInterval(this.keepaliveTimer);
      this.keepaliveTimer = null;
    }
  }
}
