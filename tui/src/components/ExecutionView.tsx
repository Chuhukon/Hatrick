import React, { useEffect, useRef, useState } from "react";
import { useKeyboard } from "@opentui/react";
import type { ExecutionStep, PluginActionType, PluginMetadata } from "../types";
import { ActionExecutor, buildExecutionSteps } from "../services/executor";

interface ExecutionViewProps {
  stagedActions: Map<string, PluginActionType>;
  allPlugins: PluginMetadata[];
  onFinish: () => void;
}

export function ExecutionView({
  stagedActions,
  allPlugins,
  onFinish,
}: ExecutionViewProps) {
  const [steps, setSteps] = useState<ExecutionStep[]>([]);
  const [logs, setLogs] = useState<string[]>([]);
  const [completed, setCompleted] = useState(false);
  const [summary, setSummary] = useState<{
    total: number;
    success: number;
    failed: number;
    elapsedSeconds: number;
  } | null>(null);

  const executorRef = useRef<ActionExecutor | null>(null);

  useEffect(() => {
    const { steps: initialSteps, commands } = buildExecutionSteps(
      stagedActions,
      allPlugins
    );
    setSteps(initialSteps);

    const executor = new ActionExecutor();
    executorRef.current = executor;

    executor.run(initialSteps, commands, {
      onStepChange: (updatedStep) => {
        setSteps((prev) =>
          prev.map((s) => (s.id === updatedStep.id ? updatedStep : s))
        );
      },
      onLog: (chunk) => {
        setLogs((prev) => {
          const split = chunk.split("\n");
          const next = [...prev, ...split];
          // Keep up to 300 lines in buffer for performance
          return next.slice(-300);
        });
      },
      onComplete: (res) => {
        setCompleted(true);
        setSummary(res);
      },
    });

    return () => {
      executor.abort();
    };
  }, []);

  useKeyboard((event) => {
    if (completed && (event.name === "return" || event.name === "q")) {
      onFinish();
    }
  });

  // Visible log window: last 15 lines
  const visibleLogs = logs.slice(-15);

  return (
    <box
      flexDirection="column"
      width="100%"
      flexGrow={1}
      borderStyle="single"
      borderColor={completed ? (summary?.failed === 0 ? "green" : "yellow") : "cyan"}
      title={completed ? " Execution Finished " : " Executing Installation "}
      paddingLeft={1}
      paddingRight={1}
      gap={1}
    >
      {/* Step checklist */}
      <box flexDirection="column">
        <text fg="white">
          <b>Installation Progress:</b>
        </text>
        {steps.map((step) => {
          let statusIcon = "[ ]";
          let statusColor = "gray";

          if (step.status === "running") {
            statusIcon = "[⟳]";
            statusColor = "cyan";
          } else if (step.status === "success") {
            statusIcon = "[✓]";
            statusColor = "green";
          } else if (step.status === "failed") {
            statusIcon = "[✗]";
            statusColor = "red";
          }

          return (
            <box key={step.id} flexDirection="row" gap={1}>
              <text fg={statusColor}>
                <b>{statusIcon}</b>
              </text>
              <text fg={step.status === "running" ? "white" : "gray"}>
                {step.status === "running" ? <b>{step.title}</b> : step.title}
              </text>
            </box>
          );
        })}
      </box>

      {/* Terminal log output */}
      <box
        flexDirection="column"
        flexGrow={1}
        borderStyle="single"
        borderColor="gray"
        title=" Output Log "
        paddingLeft={1}
        paddingRight={1}
      >
        {visibleLogs.length === 0 ? (
          <text fg="gray">Waiting for command output...</text>
        ) : (
          visibleLogs.map((line, idx) => (
            <text key={idx} fg="gray">
              {line || " "}
            </text>
          ))
        )}
      </box>

      {/* Completion Summary */}
      {completed && summary && (
        <box
          flexDirection="column"
          borderStyle="single"
          borderColor="green"
          paddingLeft={1}
          paddingRight={1}
        >
          <box flexDirection="row" gap={2}>
            <text fg="green">
              <b>All steps finished in {summary.elapsedSeconds}s!</b>
            </text>
            <text fg="green">Succeeded: {summary.success}</text>
            <text fg={summary.failed > 0 ? "red" : "gray"}>
              Failed: {summary.failed}
            </text>
          </box>
          <text fg="yellow">
            Press [Enter] or [q] to return or exit Hatrick.
          </text>
        </box>
      )}
    </box>
  );
}
