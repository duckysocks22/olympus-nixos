import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const MAX_HUNKS = 3;
const MAX_LINES = 12;

let enabled = true;

function clip(value: string, limit: number): string {
  const lines = value.split("\n");
  if (lines.length <= limit) return lines.join("\n");
  const shown = lines.slice(0, limit).join("\n");
  return `${shown}\n… ${lines.length - limit} more lines`;
}

function writePreview(input: { path?: string; content?: string }): string {
  const content = input.content ?? "";
  const lines = content === "" ? 0 : content.split("\n").length;
  return `${input.path ?? "(no path)"} — ${lines} lines\n\n${clip(content, MAX_LINES)}`;
}

type EditPair = { oldText?: string; newText?: string };

function editPreview(input: { path?: string; edits?: EditPair[] }): string {
  const edits = input.edits ?? [];
  const hunks = edits.slice(0, MAX_HUNKS).map((pair, index) => {
    const removed = clip(pair.oldText ?? "", MAX_LINES);
    const added = clip(pair.newText ?? "", MAX_LINES);
    const body = removed
      .split("\n")
      .map((line) => `- ${line}`)
      .concat(
        added
          .split("\n")
          .map((line) => `+ ${line}`),
      )
      .join("\n");
    return `--- edit ${index + 1} ---\n${body}`;
  });
  const rest = edits.length > MAX_HUNKS ? `\n… ${edits.length - MAX_HUNKS} more edits` : "";
  return `${input.path ?? "(no path)"}\n\n${hunks.join("\n\n")}${rest}`;
}

function summarize(input: unknown, toolName: string): string {
  if (toolName === "write") {
    return writePreview((input ?? {}) as { path?: string; content?: string });
  }
  return editPreview((input ?? {}) as { path?: string; edits?: EditPair[] });
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("confirm-edits", {
    description: "Show or toggle the edit/write confirmation gate",
    handler: async (args, ctx) => {
      const arg = (args ?? "").trim().toLowerCase();
      if (arg === "on") enabled = true;
      if (arg === "off") enabled = false;
      if (arg === "on" || arg === "off") {
        ctx.ui.notify(`confirm-edits: ${enabled ? "on" : "off"}`, "info");
      }
      if (arg !== "on" && arg !== "off") {
        ctx.ui.notify(
          `confirm-edits: ${enabled ? "on" : "off"} — every edit/write waits for your approval; /confirm-edits off lets this session through`,
          "info",
        );
      }
    },
  });

  pi.on("tool_call", async (event, ctx) => {
    if (!enabled) return;
    if (event.toolName !== "edit" && event.toolName !== "write") return;

    if (!ctx.hasUI) {
      return {
        block: true,
        reason: `${event.toolName} needs the user's approval, but this session has no UI to ask in. Report the proposed change to the user and stop; do not retry.`,
      };
    }

    const approved = await ctx.ui.confirm(
      `Approve ${event.toolName}?`,
      summarize(event.input, event.toolName),
    );
    if (approved) return;

    return {
      block: true,
      reason: `The user rejected this ${event.toolName}. Do not retry it. Explain the change in prose and let them decide what happens next.`,
    };
  });
}
