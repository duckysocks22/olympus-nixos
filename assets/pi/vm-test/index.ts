import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const START_TIMEOUT = 60 * 60 * 1000;
const COMMAND_TIMEOUT = 120_000;
const HOSTS = [
  "athena-nixos",
  "circe-nixos",
  "dionysus-nixos",
  "ariadne-nixos",
] as const;
const HOST_SCHEMA = Type.Union(HOSTS.map((host) => Type.Literal(host)));
const startedHosts = new Set<string>();

const guidelines = [
  "Use vm_start to boot a host configuration, vm_ssh to run commands inside it, and vm_logs when sshd never comes up; stop it with vm_stop when you are done.",
  "VMs started with vm_start are stopped automatically when the pi session exits, and an owner watchdog stops them even if pi is Ctrl-C'd, has its terminal closed, or crashes; still call vm_stop as soon as you are finished to free memory and ports.",
  "After a userspace/service/config change, use vm_switch to apply the current flake into the running VM instead of rebooting; kernel, initrd, boot, and disko changes still require vm_stop followed by vm_start.",
  "VMs are ephemeral: every vm_start creates a fresh disk overlay and vm_stop discards it. Copy anything you need out before stopping.",
  "Boot the VM that matches the configuration you changed (e.g. circe-nixos for circe.nix); one VM per host at a time.",
  "A start builds the full system and disk image, so allow several minutes on the first run after a change.",
  "For graphics work keep the default display: auto/vnc uses software rendering (llvmpipe) over a localhost VNC server, so the niri greeter renders and vm_screenshot captures the framebuffer; a human can watch via vncviewer. Use --display egl only when you need virgl, but then QEMU screendump does not work on the GL surface.",
];

export default function (pi: ExtensionAPI) {
  pi.on("session_shutdown", async () => {
    const hosts = [...startedHosts];
    startedHosts.clear();
    await Promise.allSettled(
      hosts.map((host) =>
        pi.exec("vm-test", ["stop", host], { timeout: COMMAND_TIMEOUT }),
      ),
    );
  });

  async function isRunning(host: string): Promise<boolean> {
    const result = await pi.exec("vm-test", ["status", host], {
      timeout: 15_000,
    });
    return result.code === 0 && result.stdout.includes(" running ");
  }

  async function run(
    args: string[],
    options: {
      timeout?: number;
      signal?: AbortSignal;
      allowFailure?: boolean;
    } = {},
  ) {
    const result = await pi.exec("vm-test", args, {
      timeout: options.timeout ?? COMMAND_TIMEOUT,
      signal: options.signal,
    });
    if (result.code !== 0 && !options.allowFailure) {
      const detail = result.stderr.trim() || result.stdout.trim() || "no output";
      throw new Error(
        `vm-test ${args.join(" ")} exited with ${result.code}:\n${detail}`,
      );
    }
    return result;
  }

  pi.registerTool({
    name: "vm_start",
    label: "Start VM",
    description:
      "Build a NixOS host configuration into a QEMU VM and boot it headless with SSH forwarded to localhost. " +
      "The default display is software rendering over a localhost VNC server, which supports screenshots and lets a human view the guest desktop. " +
      "Returns once sshd answers as root. The build can take several minutes; the VM keeps running after the tool returns.",
    promptSnippet: "Boot a host configuration in a headless QEMU VM",
    promptGuidelines: guidelines,
    parameters: Type.Object({
      host: HOST_SCHEMA,
      display: Type.Optional(
        Type.Union(
          [
            Type.Literal("auto"),
            Type.Literal("vnc"),
            Type.Literal("egl"),
            Type.Literal("none"),
            Type.Literal("gtk"),
          ],
          {
            description:
              "Display backend; auto/vnc is software-rendered VNC (QEMU screendump works), egl adds a virgl GL context (use vm_screenshot guest: true), none/gtk are raw QEMU displays",
          },
        ),
      ),
    }),
    async execute(_toolCallId, params, signal) {
      const args = ["start", params.host, "--owner-pid", String(process.pid)];
      if (params.display) {
        args.push("--display", params.display);
      }
      if (!(await isRunning(params.host))) {
        startedHosts.add(params.host);
      }
      const result = await run(args, { timeout: START_TIMEOUT, signal });
      return {
        content: [{ type: "text", text: result.stdout.trim() }],
        details: { host: params.host },
      };
    },
  });

  pi.registerTool({
    name: "vm_switch",
    label: "Switch VM config",
    description:
      "Build the current flake's VM variant for a host, copy the closure into the running VM, and activate it with switch-to-configuration. " +
      "Use this for userspace, service, and home-manager changes without rebooting; kernel, initrd, boot, or disko changes still need vm_stop + vm_start.",
    promptSnippet: "Apply the current flake config into a running VM",
    promptGuidelines: guidelines,
    parameters: Type.Object({
      host: HOST_SCHEMA,
    }),
    async execute(_toolCallId, params, signal) {
      const result = await run(["switch", params.host], {
        timeout: START_TIMEOUT,
        signal,
      });
      return {
        content: [{ type: "text", text: result.stdout.trim() }],
        details: { host: params.host },
      };
    },
  });

  pi.registerTool({
    name: "vm_stop",
    label: "Stop VM",
    description:
      "Stop a running test VM and discard its ephemeral disk overlay.",
    promptSnippet: "Stop a test VM",
    promptGuidelines: guidelines,
    parameters: Type.Object({
      host: HOST_SCHEMA,
    }),
    async execute(_toolCallId, params, signal) {
      const result = await run(["stop", params.host], { signal });
      startedHosts.delete(params.host);
      return {
        content: [{ type: "text", text: result.stdout.trim() }],
        details: { host: params.host },
      };
    },
  });

  pi.registerTool({
    name: "vm_status",
    label: "VM status",
    description:
      "List running test VMs with their pid, forwarded SSH port, and serial log path.",
    promptSnippet: "List running test VMs",
    promptGuidelines: guidelines,
    parameters: Type.Object({
      host: Type.Optional(HOST_SCHEMA),
    }),
    async execute(_toolCallId, params, signal) {
      const args = ["status"];
      if (params.host) {
        args.push(params.host);
      }
      const result = await run(args, { signal });
      return {
        content: [{ type: "text", text: result.stdout.trim() }],
        details: { host: params.host ?? null },
      };
    },
  });

  pi.registerTool({
    name: "vm_ssh",
    label: "Run command in VM",
    description:
      "Run a command inside a running test VM as root over SSH and return stdout, stderr, and the exit code. " +
      "Use this to inspect services, logs, and files in the guest.",
    promptSnippet: "Run a command inside a test VM",
    promptGuidelines: guidelines,
    parameters: Type.Object({
      host: HOST_SCHEMA,
      command: Type.String({
        description: "Shell command to run in the guest, e.g. systemctl --failed",
      }),
    }),
    async execute(_toolCallId, params, signal) {
      const result = await run(["ssh", params.host, params.command], {
        signal,
        allowFailure: true,
      });
      const output = [
        result.stdout.trimEnd(),
        result.stderr.trim() ? `stderr:\n${result.stderr.trim()}` : "",
        `exit code: ${result.code}`,
      ]
        .filter(Boolean)
        .join("\n");
      return {
        content: [{ type: "text", text: output || "(no output)" }],
        details: { host: params.host, code: result.code },
      };
    },
  });

  pi.registerTool({
    name: "vm_logs",
    label: "VM serial logs",
    description:
      "Show the guest serial console log. Use when the VM starts but SSH never answers, or to inspect boot-time output.",
    promptSnippet: "Read a test VM serial boot log",
    promptGuidelines: guidelines,
    parameters: Type.Object({
      host: HOST_SCHEMA,
      lines: Type.Optional(
        Type.Number({ description: "Trailing lines to return, default 80" }),
      ),
    }),
    async execute(_toolCallId, params, signal) {
      const lines = Math.max(1, Math.min(2000, Math.trunc(params.lines ?? 80)));
      const result = await run(["logs", params.host, String(lines)], { signal });
      return {
        content: [{ type: "text", text: result.stdout.trimEnd() || "(empty log)" }],
        details: { host: params.host, lines },
      };
    },
  });

  pi.registerTool({
    name: "vm_screenshot",
    label: "VM screenshot",
    description:
      "Capture the guest framebuffer to a PNG file and return its path. Requires a running VM; the default VNC display supports screendump, as does gtk. Read the returned file to view the guest desktop.",
    promptSnippet: "Capture a test VM screenshot",
    promptGuidelines: guidelines,
    parameters: Type.Object({
      host: HOST_SCHEMA,
      guest: Type.Optional(
        Type.Boolean({
          description:
            "Capture from inside the niri session with grim; required when the display backend is egl",
        }),
      ),
    }),
    async execute(_toolCallId, params, signal) {
      const args = ["screenshot", params.host];
      if (params.guest) {
        args.push("--guest");
      }
      const result = await run(args, { signal });
      const path = result.stdout.trim();
      return {
        content: [
          {
            type: "text",
            text: `Screenshot saved to ${path}. Read it with the read tool to inspect the guest display.`,
          },
        ],
        details: { host: params.host, path },
      };
    },
  });
}
