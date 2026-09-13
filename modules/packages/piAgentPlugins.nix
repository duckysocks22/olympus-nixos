{ inputs, self, ... }:

{
  flake.homeModules.pi-status-line =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      cfg = config.programs.pi-coding-agent;
      boolStr = b: if b then "true" else "false";

      statusLineFile = pkgs.writeText "pi-status-line-extension.ts" ''
        import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
        import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
        import { appendFileSync, readdirSync, readFileSync, statSync } from "node:fs";
        import { join } from "node:path";

        const SHOW_MODEL = ${boolStr cfg.statusLine.showModel};
        const SHOW_CONTEXT = ${boolStr cfg.statusLine.showContext};
        const SHOW_TOKENS = ${boolStr cfg.statusLine.showTokens};
        const SHOW_COST = ${boolStr cfg.statusLine.showCost};
        const SHOW_BRANCH = ${boolStr cfg.statusLine.showBranch};
        const SESSION_DIR = "${cfg.configDir}/sessions";
        const USAGE_FIVE_HOUR = ${toString cfg.statusLine.usage.fiveHour};
        const USAGE_WEEKLY = ${toString cfg.statusLine.usage.weekly};
        const USAGE_MONTHLY = ${toString cfg.statusLine.usage.monthly};
        const USAGE_LIVE = ${boolStr cfg.statusLine.usage.live};
        const USAGE_PROVIDER = ${builtins.toJSON cfg.statusLine.usage.provider};
        const USAGE_ACCOUNT_BASE = ${builtins.toJSON cfg.statusLine.usage.accountBaseUrl};

        interface LiveWindow {
          percent: number;
          resetTs: number;
        }
        let liveUsage: { rolling: LiveWindow; weekly: LiveWindow; monthly: LiveWindow; fetchedAt: number } | null =
          null;

        async function fetchUsage(ctx: any): Promise<void> {
          try {
            const registry = ctx.modelRegistry;
            if (!registry || typeof registry.getProviderAuth !== "function") return;
            const resolved = await registry.getProviderAuth(USAGE_PROVIDER);
            const a = resolved?.auth;
            const apiKey = a?.apiKey ?? "";
            const base = String(a?.baseUrl ?? USAGE_ACCOUNT_BASE).replace(/\/$/, "");
            if (!apiKey || !base) return;
            const res = await fetch(base + "/usage", {
              headers: { Authorization: "Bearer " + apiKey },
              signal: AbortSignal.timeout(8000),
            });
            if (!res.ok) return;
            const data: any = await res.json();
            const u = data && data.usage;
            if (!u) return;
            const win = (w: any): LiveWindow => ({
              percent: typeof w?.percent === "number" ? w.percent : 0,
              resetTs: Date.parse(w?.resetsAt ?? "") || 0,
            });
            liveUsage = {
              rolling: win(u.rolling),
              weekly: win(u.weekly),
              monthly: win(u.monthly),
              fetchedAt: Date.now(),
            };
          } catch {
            /* keep the last successful snapshot */
          }
        }

        const usage = { d: 0, wk: 0, mo: 0 };

        function scanUsage(): void {
          const now = Date.now();
          const fiveStart = now - 5 * 3600000;
          const dayStart = fiveStart;
          const weekStart = now - 7 * 86400000;
          const monthDate = new Date(now);
          const monthStart = now - 30 * 86400000;
          const floor = Math.min(dayStart, weekStart, monthStart) - 3600000;
          let files: string[] = [];
          try {
            files = readdirSync(SESSION_DIR, { recursive: true }).filter((f) => f.endsWith(".jsonl"));
          } catch {
            return;
          }
          let d = 0;
          let wk = 0;
          let mo = 0;
          for (const rel of files) {
            const p = join(SESSION_DIR, rel);
            try {
              if (statSync(p).mtimeMs < floor) continue;
              const lines = readFileSync(p, "utf8").split("\n");
              for (const line of lines) {
                if (!line.trim()) continue;
                let e: any;
                try {
                  e = JSON.parse(line);
                } catch {
                  continue;
                }
                if (e.type !== "message" || !e.message || e.message.role !== "assistant") continue;
                const u = e.message.usage;
                const raw = e.message.timestamp ?? e.timestamp ?? "";
                const ts = typeof raw === "number" ? raw : Date.parse(String(raw));
                if (!u || !Number.isFinite(ts)) continue;
                const c = u.cost ? u.cost.total || 0 : 0;
                if (ts >= dayStart) d += c;
                if (ts >= weekStart) wk += c;
                if (ts >= monthStart) mo += c;
              }
            } catch {
              continue;
            }
          }
          usage.d = d;
          usage.wk = wk;
          usage.mo = mo;
        }

        function nextMidnight(now: number): number {
          const d = new Date(now);
          d.setHours(24, 0, 0, 0);
          return d.getTime();
        }

        function nextMonday(now: number): number {
          const d = new Date(now);
          const dow = (d.getDay() + 6) % 7;
          const days = dow === 0 ? 7 : 7 - dow;
          d.setDate(d.getDate() + days);
          d.setHours(0, 0, 0, 0);
          return d.getTime();
        }

        function nextMonthStart(now: number): number {
          const d = new Date(now);
          d.setDate(1);
          d.setHours(0, 0, 0, 0);
          d.setMonth(d.getMonth() + 1);
          return d.getTime();
        }

        function meterLive(label: string, win: LiveWindow, now: number, theme: { fg: (color: string, text: string) => string }): string {
          const pct = Math.min(100, Math.max(0, Math.round(win.percent)));
          const color = pct < 50 ? "success" : pct < 75 ? "warning" : "error";
          const filled = Math.min(10, Math.floor((pct + 5) / 10));
          const bar = theme.fg(color, "█".repeat(filled)) + theme.fg("dim", "░".repeat(10 - filled));
          const diff = win.resetTs > now ? win.resetTs - now : 0;
          const days = Math.floor(diff / 86400000);
          const hh = Math.floor((diff % 86400000) / 3600000);
          const mm = Math.floor((diff % 3600000) / 60000);
          let resetLabel = mm + "m";
          if (days > 0) resetLabel = days + "d" + hh + "h";
          else if (diff >= 3600000) resetLabel = hh + "h" + String(mm).padStart(2, "0") + "m";
          return (
            theme.fg("dim", label + " ") +
            bar +
            " " +
            theme.fg(color, String(pct) + "%") +
            theme.fg("dim", " ↺" + resetLabel)
          );
        }

        function meterStr(label: string, cost: number, cap: number, resetTs: number, now: number, theme: { fg: (color: string, text: string) => string }): string {
          const pct = Math.min(100, Math.round((cost / cap) * 100));
          const color = pct < 50 ? "success" : pct < 75 ? "warning" : "error";
          const filled = Math.min(10, Math.floor((pct + 5) / 10));
          const bar = theme.fg(color, "█".repeat(filled)) + theme.fg("dim", "░".repeat(10 - filled));
          const diff = Math.max(0, resetTs - now);
          const hh = Math.floor(diff / 3600000);
          const mm = Math.floor((diff % 3600000) / 60000);
          const resetLabel = diff >= 3600000 ? hh + "h" + String(mm).padStart(2, "0") + "m" : mm + "m";
          return (
            theme.fg("dim", label + " ") +
            bar +
            " " +
            theme.fg(color, String(pct) + "%") +
            theme.fg("dim", " ↺" + resetLabel)
          );
        }

        export default function (pi: ExtensionAPI) {
          let footerTui: { requestRender(force?: boolean): void } | undefined;
          let usageTimer: ReturnType<typeof setInterval> | null = null;
          let lastCtx: any = null;

          pi.on("model_select", async () => {
            footerTui?.requestRender();
          });

          pi.on("thinking_level_select", async () => {
            footerTui?.requestRender();
          });

          pi.on("turn_end", async () => {
            if (USAGE_LIVE) {
              void fetchUsage(lastCtx).then(() => footerTui?.requestRender());
            } else {
              scanUsage();
            }
            footerTui?.requestRender();
          });

          pi.on("session_shutdown", async () => {
            if (usageTimer) {
              clearInterval(usageTimer);
              usageTimer = null;
            }
            footerTui = undefined;
            lastCtx = null;
          });

          pi.on("session_start", async (_event, ctx) => {
            try {
            if (!ctx.hasUI) return;

            if (USAGE_LIVE) {
              void fetchUsage(ctx).then(() => footerTui?.requestRender());
              lastCtx = ctx;
            } else {
              scanUsage();
            }
            ctx.ui.setFooter((tui, theme, footerData) => {
              footerTui = tui;
              const unsub = footerData.onBranchChange(() => tui.requestRender());

              return {
                dispose: unsub,
                invalidate() {},
                render(width: number): string[] {
                  try {
                  const parts: string[] = [];

                  if (SHOW_MODEL) {
                    const model = ctx.model ? ctx.model.id : "no-model";
                    const level = String(ctx.thinkingLevel ?? "off");
                    let levelColor = "dim";
                    if (level === "low" || level === "medium") levelColor = "success";
                    else if (level === "high" || level === "xhigh" || level === "max") levelColor = "accent";
                    parts.push(theme.fg("accent", "◆ " + model) + " " + theme.fg(levelColor, level));
                  }

                  if (SHOW_CONTEXT) {
                    const usage = ctx.getContextUsage();
                    const pct =
                      usage && usage.percent !== null && usage.percent !== undefined
                        ? Math.round(usage.percent)
                        : null;
                    if (pct === null) {
                      parts.push(theme.fg("dim", "ctx --"));
                    } else {
                      const color = pct < 50 ? "success" : pct < 75 ? "warning" : "error";
                      const filled = Math.min(10, Math.floor((pct + 5) / 10));
                      const bar = theme.fg(color, "█".repeat(filled)) + theme.fg("dim", "░".repeat(10 - filled));
                      parts.push(theme.fg("dim", "ctx ") + bar + " " + theme.fg(color, String(pct) + "%"));
                    }
                  }

                  if (SHOW_TOKENS || SHOW_COST) {
                    let input = 0;
                    let output = 0;
                    let cost = 0;
                    for (const e of ctx.sessionManager.getBranch()) {
                      if (e.type === "message" && e.message.role === "assistant") {
                        const m: any = e.message;
                        if (m.usage) {
                          input += m.usage.input || 0;
                          output += m.usage.output || 0;
                          if (m.usage.cost) cost += m.usage.cost.total || 0;
                        }
                      }
                    }
                    const fmt = (n: number) => (n < 1000 ? String(n) : (n / 1000).toFixed(1) + "k");
                    const bits: string[] = [];
                    if (SHOW_TOKENS) bits.push("↑" + fmt(input) + " ↓" + fmt(output));
                    if (SHOW_COST) bits.push("$" + cost.toFixed(2));
                    if (bits.length > 0) parts.push(theme.fg("dim", bits.join(" ")));
                  }

                  if (SHOW_BRANCH) {
                    const branch = footerData.getGitBranch();
                    if (branch) parts.push(theme.fg("warning", branch));
                  }

                  if (USAGE_LIVE && liveUsage) {
                    const now = Date.now();
                    parts.push(
                      [
                        meterLive("5h", liveUsage.rolling, now, theme),
                        meterLive("wk", liveUsage.weekly, now, theme),
                        meterLive("mo", liveUsage.monthly, now, theme),
                      ].join(" "),
                    );
                  } else if (USAGE_FIVE_HOUR > 0 || USAGE_WEEKLY > 0 || USAGE_MONTHLY > 0) {
                    const now = Date.now();
                    const meters: string[] = [];
                    if (USAGE_FIVE_HOUR > 0) meters.push(meterStr("5h", usage.d, USAGE_FIVE_HOUR, now, now, theme));
                    if (USAGE_WEEKLY > 0) meters.push(meterStr("wk", usage.wk, USAGE_WEEKLY, now, now, theme));
                    if (USAGE_MONTHLY > 0) meters.push(meterStr("mo", usage.mo, USAGE_MONTHLY, now, now, theme));
                    if (meters.length > 0) parts.push(meters.join(" "));
                  }

                  return [truncateToWidth(parts.join(theme.fg("dim", " | ")), width)];
                  } catch (e: any) {
                    return [truncateToWidth("statusline-err: " + String(e), width)];
                  }
                },
              };
            });

            if (usageTimer) {
              clearInterval(usageTimer);
              usageTimer = null;
            }
            usageTimer = setInterval(() => {
              if (!footerTui || !lastCtx) return;
              if (USAGE_LIVE) {
                void fetchUsage(lastCtx).then(() => footerTui?.requestRender());
              } else {
                scanUsage();
              }
              footerTui.requestRender();
            }, 60000);
          } catch (e: any) {
            console.error("[pi-status-line] session_start failed: " + String(e));
          }
          });
        }
      '';
    in
    {
      options.programs.pi-coding-agent.statusLine = {
        enable = lib.mkEnableOption "pi custom status line (ported from claude-statusline)";

        showModel = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Show the active model and thinking level.";
        };
        showContext = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Show the context-window meter (green under 50%, yellow under 75%, red above).";
        };
        showTokens = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Show session input/output token totals.";
        };
        showCost = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Show the accumulated session cost.";
        };
        showBranch = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Show the current git branch.";
        };

        usage = {
          fiveHour = lib.mkOption {
            type = lib.types.float;
            default = 12.0;
            description = "5-hour rolling spend cap in USD (OpenCode Go GLM-5.3-Flash quota: $12 / 5 hr).";
          };
          weekly = lib.mkOption {
            type = lib.types.float;
            default = 30.0;
            description = "Rolling 7-day spend cap in USD (OpenCode Go GLM-5.3-Flash quota: $30 / week).";
          };
          monthly = lib.mkOption {
            type = lib.types.float;
            default = 60.0;
            description = "Rolling 30-day spend cap in USD (OpenCode Go GLM-5.3-Flash quota: $60 / month).";
          };
          live = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Fetch live usage percentages from the provider's account API (falls back to local session aggregation).";
          };
          provider = lib.mkOption {
            type = lib.types.str;
            default = "opencode-go";
            description = "Provider id used to resolve the API credential for live usage fetching.";
          };
          accountBaseUrl = lib.mkOption {
            type = lib.types.str;
            default = "https://opencode.ai/zen/go/v1";
            description = "Account API base the /usage endpoint is fetched from (provider auth often omits it).";
          };
        };
      };

      config = lib.mkIf cfg.statusLine.enable {
        home.file."${cfg.configDir}/extensions/pi-status-line/index.ts".source = statusLineFile;
      };
    };

  flake.homeModules.piDSH-Pet =
    {
      pkgs,
      config,
      lib,
      inputs,
      ...
    }:
    let
      cfg = config.programs.pi-coding-agent;
      boolStr = b: if b then "true" else "false";

      dshPetTarball = pkgs.fetchurl {
        url = "https://registry.npmjs.org/dsh-pet/-/dsh-pet-0.2.8.tgz";
        hash = "sha256-sXE4UjE3Rs/HM09DRzEbDz75chUjxk199MGMKDtR4jg=";
      };

      frameStride = if cfg.pet.sprite.fps >= 1 then builtins.div 24 cfg.pet.sprite.fps else 4;
      frameIntervalMs =
        let
          raw = (frameStride * 1000.0) / 24.0 / cfg.pet.sprite.speed;
          rounded = builtins.floor (raw + 0.5);
        in
        if rounded < 30 then 30 else rounded;

      petBboxScript = pkgs.writeText "pet-bbox.py" ''
        import json, sys
        w, h, outdir = int(sys.argv[1]), int(sys.argv[2]), sys.argv[3]
        pairs = sys.argv[4:]
        TH, M = 8, 4
        left, right = w, -1
        boxes = {}
        for pair in pairs:
            path, name = pair.split(":", 1)
            data = open(path, "rb").read()
            n = len(data) // (w * h)
            l, r, t, b = w, -1, h, -1
            for f in range(n):
                fr = data[f * w * h:(f + 1) * w * h]
                for x in range(w):
                    if l <= x <= r:
                        continue
                    if max(fr[x::w]) > TH:
                        if x < l: l = x
                        if x > r: r = x
                for y in range(h):
                    if t <= y <= b:
                        continue
                    if max(fr[y * w:(y + 1) * w]) > TH:
                        if y < t: t = y
                        if y > b: b = y
            if r < 0:
                l, r, t, b = 0, w - 1, 0, h - 1
            boxes[name] = (l, r, t, b)
            left = min(left, l)
            right = max(right, r)
        cx0 = max(0, left - M)
        cx1 = min(w, right + M + 1)
        cw = cx1 - cx0
        for pair in pairs:
            name = pair.split(":", 1)[1]
            l, r, t, b = boxes[name]
            sy0 = max(0, t - M)
            sy1 = min(h, b + M + 1)
            json.dump(
                {"x": cx0, "y": sy0, "w": cw, "h": sy1 - sy0,
                 "leftFrac": max(0, l - cx0) / cw, "rightFrac": max(0, cx1 - 1 - r) / cw},
                open(f"{outdir}/{name}/meta.json", "w"),
            )
            open(f"{outdir}/{name}/crop.txt", "w").write(
                str(cw) + ":" + str(sy1 - sy0) + ":" + str(cx0) + ":" + str(sy0)
            )
      '';

      piPetFrames = pkgs.stdenvNoCC.mkDerivation {
        pname = "pi-pet-frames";
        version = "0.2.8";

        dontUnpack = true;
        nativeBuildInputs = [
          pkgs.ffmpeg
          pkgs.python3
        ];

        buildPhase =
          let
            stateName = e: builtins.elemAt (builtins.split ":" e) 2;
            spriteSources = [
              # The sources are in Chinese since the plugin was translated to english from it's source
              "待机呼吸休闲:idle"
              "工作状态-思考冒泡:thinking"
              "工作状态-忙碌点按:working"
              "工作状态-原地踱步张望:waiting"
              "工作状态-雀跃庆祝:success"
              "工作状态-垂头叹气冒汗:error"
              "点击回应-开心跃动:click"
              "碎碎念-发呆碎碎念:whisper"
            ];
          in
          ''
            mkdir src
            tar -xzf ${dshPetTarball} -C src
            mkdir -p $out
          ''
          + lib.concatMapStrings (
            entry:
            let
              src = builtins.head (builtins.split ":" entry);
              name = builtins.elemAt (builtins.split ":" entry) 2;
            in
            ''
              mkdir -p "$out/${name}"
              ffmpeg -v error \
                -c:v libvpx-vp9 \
                -i "src/package/assets/webm/${src}.webm" \
                -vf "extractplanes=a" -f rawvideo "alpha-${name}.raw"
            ''
          ) spriteSources
          + ''
            CROP="$(python3 ${petBboxScript} 640 360 "$out" ${
              lib.concatStringsSep " " (map (e: "alpha-${stateName e}.raw:${stateName e}") spriteSources)
            })"
          ''
          + lib.concatMapStrings (
            entry:
            let
              src = builtins.head (builtins.split ":" entry);
              name = builtins.elemAt (builtins.split ":" entry) 2;
            in
            ''
              CROP="$(cat "$out/${name}/crop.txt")"
              ffmpeg -v error \
                -c:v libvpx-vp9 \
                -i "src/package/assets/webm/${src}.webm" \
                -vf "select='not(mod(n\,${toString frameStride}))',crop=$CROP,scale=${
                  toString (cfg.pet.sprite.size * 8)
                }:-1:flags=lanczos,format=rgba" \
                -pix_fmt rgba -fps_mode passthrough -vsync 0 \
                "$out/${name}/f_%03d.png"
            ''
          ) spriteSources;

        installPhase = ''
          runHook preInstall
          runHook postInstall
        '';

        meta = {
          description = "dsh-pet animation frames for the pi TUI pet widget";
          license = lib.licenses.mit;
        };
      };

      extensionFile = pkgs.writeText "pi-pet-extension.ts" ''
        import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
        import { Image, getCapabilities, getCellDimensions, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
        import { readFileSync, readdirSync } from "node:fs";

        const PET_NAME = ${builtins.toJSON cfg.pet.name};
        const PET_EMOJI = ${builtins.toJSON cfg.pet.emoji};
        const POSITION_HORIZONTAL = ${builtins.toJSON cfg.pet.sprite.position.horizontal};
        const POSITION_VERTICAL = ${builtins.toJSON cfg.pet.sprite.position.vertical};
        const POSITION_OFFSET_X = ${toString cfg.pet.sprite.position.offsetX};
        const SPRITE_DIR = "${piPetFrames}";
        const FRAME_DIR = SPRITE_DIR;
        const SPRITE_CELLS = ${toString cfg.pet.sprite.size};
        const FRAME_INTERVAL_MS = ${toString frameIntervalMs};
        const WHISPER_INTERVAL_SEC = ${toString cfg.pet.whispers.interval};
        const WHISPERS: string[] = ${builtins.toJSON cfg.pet.whispers.messages};
        const IDLE_TEXTS: string[] = ${builtins.toJSON cfg.pet.idleTexts};
        const STATUS_TEXTS: Record<string, string[]> = {
          thinking: ${builtins.toJSON cfg.pet.workStatus.texts.thinking},
          working: ${builtins.toJSON cfg.pet.workStatus.texts.working},
          waiting: ${builtins.toJSON cfg.pet.workStatus.texts.waiting},
          success: ${builtins.toJSON cfg.pet.workStatus.texts.success},
          error: ${builtins.toJSON cfg.pet.workStatus.texts.error},
        };

        const STATES = ["idle", "thinking", "working", "waiting", "success", "error", "click", "whisper"];

        const FRAMES: Record<string, string[]> = {};
        const STATE_META: Record<string, { leftFrac: number; rightFrac: number }> = {};
        for (const state of STATES) {
          const dir = FRAME_DIR + "/" + state;
          FRAMES[state] = readdirSync(dir)
            .filter((f) => f.endsWith(".png"))
            .sort()
            .map((f) => readFileSync(dir + "/" + f).toString("base64"));
          STATE_META[state] = JSON.parse(readFileSync(dir + "/meta.json", "utf8"));
        }

        const ID_BASE = 0x70000000 + Math.floor(Math.random() * 0x0fffffff);
        let idCounter = 0;

        function pngSize(b64: string): { w: number; h: number } {
          const buf = Buffer.from(b64.slice(0, 64), "base64");
          return { w: buf.readUInt32BE(16), h: buf.readUInt32BE(20) };
        }

        function chunked(params: string, b64: string): string {
          const CHUNK = 4096;
          let out = "";
          let first = true;
          for (let i = 0; i < b64.length; i += CHUNK) {
            const isLast = i + CHUNK >= b64.length;
            const head = first ? "\x1b_G" + params + ",m=" + (isLast ? "0" : "1") + ";" : "\x1b_Gm=" + (isLast ? "0" : "1") + ";";
            out += head + b64.slice(i, i + CHUNK) + "\x1b\\";
            first = false;
          }
          if (first) out += "\x1b_G" + params + ",m=0;\x1b\\";
          return out;
        }

        function transmitFrame(state: string, id: number, frameIdx: number, cols: number, rows: number): string {
          return chunked("a=T,f=100,i=" + id + ",q=2,C=1,c=" + cols + ",r=" + rows, FRAMES[state][frameIdx]);
        }

        function pickRandom<T>(arr: T[]): T {
          return arr[Math.floor(Math.random() * arr.length)];
        }

        function alignPad(contentWidth: number, width: number): string {
          if (POSITION_HORIZONTAL === "left") return "";
          if (POSITION_HORIZONTAL === "center") {
            return " ".repeat(Math.max(0, Math.floor((width - contentWidth) / 2)));
          }
          return " ".repeat(Math.max(0, width - 2 - contentWidth));
        }

        export default function (pi: ExtensionAPI) {
          let currentState = "idle";
          let statusText = pickRandom(IDLE_TEXTS);
          let animState = "";
          let animCols = 0;
          let animRows = 0;
          let spriteLines: string[] = [];
          let widgetTui: { requestRender(force?: boolean): void } | undefined;
          let bubbleText = "";
          let bubbleUntil = 0;
          let whisperTimer: ReturnType<typeof setInterval> | null = null;
          let revertTimer: ReturnType<typeof setTimeout> | null = null;
          let latestCtx: any = null;
          let mutableName = PET_NAME;
          let imagesSupported = false;

          function textsFor(state: string): string[] {
            return STATUS_TEXTS[state] ?? IDLE_TEXTS;
          }

          function spritePad(width: number): string {
            const meta = STATE_META[currentState] ?? { leftFrac: 0, rightFrac: 0 };
            const rightPad = Math.round(meta.rightFrac * animCols);
            const leftPad = Math.round(meta.leftFrac * animCols);
            if (POSITION_HORIZONTAL === "left") {
              return " ".repeat(Math.max(0, leftPad + POSITION_OFFSET_X));
            }
            if (POSITION_HORIZONTAL === "center") {
              const bodyW = Math.max(1, animCols - leftPad - rightPad);
              return " ".repeat(Math.max(0, Math.floor((width - bodyW) / 2) - leftPad + POSITION_OFFSET_X));
            }
            return " ".repeat(
              Math.min(
                Math.max(0, width - 1 - animCols + rightPad - POSITION_OFFSET_X),
                Math.max(0, width - animCols),
              ),
            );
          }

          function setState(state: string, texts?: string[]): void {
            currentState = state;
            statusText = pickRandom(texts ?? textsFor(state));
            widgetTui?.requestRender();
          }

          function transientState(state: string, ms: number, texts?: string[]): void {
            if (revertTimer) {
              clearTimeout(revertTimer);
              revertTimer = null;
            }
            setState(state, texts);
            revertTimer = setTimeout(() => {
              revertTimer = null;
              setState("idle");
            }, ms);
          }

          let animId = 0;
          let frameIdx = 0;
          let frameTimer: ReturnType<typeof setInterval> | null = null;

          function ensureAnim(width: number): void {
            const cols = Math.min(SPRITE_CELLS, Math.max(1, width - 2));
            const cell = getCellDimensions();
            const { w, h } = pngSize(FRAMES[currentState][0]);
            const rows = Math.max(1, Math.ceil((h / w) * cols * (cell.widthPx / cell.heightPx)));
            if (animState === currentState && cols === animCols && rows === animRows && spriteLines.length) return;
            animState = currentState;
            animCols = cols;
            animRows = rows;
            frameIdx = 0;
            animId = ID_BASE + (idCounter++ % 0xfff0);
            spriteLines = [transmitFrame(currentState, animId, 0, cols, rows)];
            for (let i = 1; i < rows; i++) spriteLines.push("");
          }

          function bumpGeneration(): void {
            const registrar = new Image(FRAMES[currentState][frameIdx], "image/png", { fallbackColor: (s) => s }, {
              maxWidthCells: SPRITE_CELLS,
              imageId: animId,
            });
            registrar.render(animCols + 2);
          }

          function showBubble(text: string, state: string, ms: number): void {
            bubbleText = text;
            bubbleUntil = Date.now() + ms;
            transientState(state, ms);
          }

          pi.on("session_start", async (_event, ctx) => {
            latestCtx = ctx;
            if (!ctx.hasUI) return;

            ctx.ui.setWidget(
              "pi-pet",
              (tui, _theme) => {
                widgetTui = tui;
                return {
                  render: (width: number) => {
                    imagesSupported = getCapabilities().images === "kitty";
                    const lines: string[] = [];
                    if (bubbleText && Date.now() >= bubbleUntil) bubbleText = "";
                    if (imagesSupported) {
                      ensureAnim(width);
                      if (bubbleText) {
                        const text = truncateToWidth(bubbleText, Math.max(8, width - 10));
                        const tw = visibleWidth(text);
                        const padStr = spritePad(width);
                        const bodyCol = padStr.length + Math.round((STATE_META[currentState]?.leftFrac ?? 0) * animCols);
                        const boxW = tw + 4;
                        const bubPad = Math.max(0, Math.min(bodyCol - Math.floor(boxW / 2), width - boxW - 1));
                        const edge = "-".repeat(tw + 2);
                        const bottom = "+" + edge + "+";
                        const notchIdx = bodyCol - bubPad;
                        const bottomLine =
                          notchIdx >= 1 && notchIdx <= tw + 2
                            ? bottom.slice(0, notchIdx) + "v" + bottom.slice(notchIdx + 1)
                            : bottom;
                        lines.push(" ".repeat(bubPad) + "+" + edge + "+");
                        lines.push(" ".repeat(bubPad) + "| " + text + " |"
                        );
                        lines.push(" ".repeat(bubPad) + bottomLine);
                      }
                      lines.push(spritePad(width) + spriteLines[0]);
                      for (let i = 1; i < spriteLines.length; i++) lines.push(spriteLines[i]);
                      const statusFull = truncateToWidth(PET_EMOJI + " " + mutableName + " " + statusText, width - 2);
                      lines.push(alignPad(visibleWidth(statusFull), width) + statusFull);
                    } else {
                      if (bubbleText) {
                        const text = truncateToWidth(bubbleText, width - 2);
                        lines.push(alignPad(visibleWidth(text), width) + text);
                      }
                      const statusFull = PET_EMOJI + " " + mutableName + " " + statusText;
                      lines.push(alignPad(visibleWidth(statusFull), width) + statusFull);
                    }
                    return lines;
                  },
                  invalidate: () => {},
                };
              },
              { placement: POSITION_VERTICAL === "below" ? "belowEditor" : "aboveEditor" },
            );

            setState("idle");

            if (whisperTimer) {
              clearInterval(whisperTimer);
              whisperTimer = null;
            }
            if (${boolStr cfg.pet.whispers.enable}) {
              whisperTimer = setInterval(() => {
                if (currentState !== "idle" || !latestCtx) return;
                const msg = pickRandom(WHISPERS);
                showBubble(msg, "whisper", 10000);
                if (${boolStr cfg.pet.notifications.enable}) {
                  latestCtx.ui.notify(PET_EMOJI + " " + mutableName + " whispers: " + msg, "info");
                }
              }, WHISPER_INTERVAL_SEC * 1000);
            }

            if (frameTimer) {
              clearInterval(frameTimer);
              frameTimer = null;
            }
            frameTimer = setInterval(() => {
              if (!imagesSupported || !widgetTui || spriteLines.length === 0) return;
              frameIdx = (frameIdx + 1) % FRAMES[currentState].length;
              bumpGeneration();
              spriteLines[0] = transmitFrame(currentState, animId, frameIdx, animCols, animRows);
              widgetTui.requestRender();
            }, ${toString frameIntervalMs});
          });

          pi.on("session_shutdown", async () => {
            if (whisperTimer) {
              clearInterval(whisperTimer);
              whisperTimer = null;
            }
            if (frameTimer) {
              clearInterval(frameTimer);
              frameTimer = null;
            }
            if (revertTimer) {
              clearTimeout(revertTimer);
              revertTimer = null;
            }
            latestCtx = null;
            widgetTui = undefined;
          });

          pi.on("agent_start", async (_event, ctx) => {
            if (!${boolStr cfg.pet.workStatus.enable}) return;
            transientState("thinking", 60000);
          });

          pi.on("turn_start", async (_event, ctx) => {
            if (!${boolStr cfg.pet.workStatus.enable}) return;
            transientState("thinking", 60000);
          });

          pi.on("tool_execution_start", async (_event, ctx) => {
            if (!${boolStr cfg.pet.workStatus.enable}) return;
            transientState("working", 60000);
          });

          pi.on("tool_execution_end", async (event, ctx) => {
            if (!${boolStr cfg.pet.workStatus.enable}) return;
            if (event.isError) {
              transientState("error", 4000);
            }
          });

          pi.on("agent_end", async (event, ctx) => {
            if (!${boolStr cfg.pet.workStatus.enable}) return;
            const hasError = event.messages.some(
              (m: any) => m.role === "toolResult" && m.isError
            );
            if (hasError) {
              transientState("error", 4000);
            } else {
              transientState("success", 4000);
            }
          });

          pi.on("ui_prompt_start", async (_event, ctx) => {
            if (!${boolStr cfg.pet.workStatus.enable}) return;
            transientState("waiting", 60000);
          });

          pi.registerCommand("pet", {
            description: "Interact with your coding companion",
            handler: async (args, ctx) => {
              const parts = args.trim().split(/\s+/);
              const cmd = parts[0]?.toLowerCase();

              if (cmd === "whisper") {
                const msg = pickRandom(WHISPERS);
                showBubble(msg, "whisper", 10000);
                ctx.ui.notify(PET_EMOJI + " " + mutableName + " says: " + msg, "info");
              } else if (cmd === "rename" && parts[1]) {
                mutableName = parts.slice(1).join(" ");
                ctx.ui.notify(PET_EMOJI + " Your companion is now named " + mutableName + "!", "info");
                setState("idle");
              } else if (cmd === "status") {
                ctx.ui.notify(PET_EMOJI + " " + mutableName + " is currently " + currentState + ".", "info");
              } else {
                showBubble("Hi! I'm " + mutableName + "~", "click", 2500);
                ctx.ui.notify(
                  PET_EMOJI + " " + mutableName + " says hi! Try: /pet whisper | /pet rename <name> | /pet status",
                  "info"
                );
              }
            },
          });
        }
      '';

    in
    {
      options.programs.pi-coding-agent.pet = {
        enable = lib.mkEnableOption "pi-coding-agent terminal pet companion (ported from dsh-pet)";

        name = lib.mkOption {
          type = lib.types.str;
          default = "Blue";
          description = "Display name of your terminal companion.";
        };

        emoji = lib.mkOption {
          type = lib.types.str;
          default = "🐱";
          description = "Emoji used in status lines and notifications.";
        };

        whispers = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Periodic whispers shown in the TUI speech bubble and notifications.";
          };
          interval = lib.mkOption {
            type = lib.types.int;
            default = 120;
            description = "Seconds between whisper attempts (only when idle).";
          };
          messages = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              "Don't forget to commit~!"
              "You're doing a great job :D"
              "Remember to stay hydrated!"
              "Maybe take a little break?"
              "Time for a coffee refill~"
            ];
            description = "Pool of whisper lines shown in the TUI speech bubble.";
          };
        };

        workStatus = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Reactive sprite states (thinking/working/waiting/success/error).";
          };
          texts = {
            thinking = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [
                "is thinking deeply..."
                "is organizing thoughts~"
                "is figuring out the next move..."
              ];
              description = "Status texts shown while the agent is thinking.";
            };
            working = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [
                "is working hard!"
                "is busy with tools~"
                "is helping out..."
              ];
              description = "Status texts shown while tools are executing.";
            };
            waiting = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [
                "is waiting for you~"
                "needs your input!"
                "is on standby..."
              ];
              description = "Status texts shown when waiting for user input.";
            };
            success = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [
                "is celebrating!"
                "did a great job!"
                "is happy everything worked~"
              ];
              description = "Status texts shown after successful completion.";
            };
            error = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [
                "is worried..."
                "ran into a problem!"
                "is confused..."
              ];
              description = "Status texts shown when an error occurs.";
            };
          };
        };

        idleTexts = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "is resting~"
            "is breathing calmly..."
            "is daydreaming..."
            "is waiting patiently~"
            "is humming a tune~"
            "is stretching..."
          ];
          description = "Status texts shown when the companion is idle.";
        };

        notifications = {
          enable = lib.mkEnableOption "TUI notifications for whispers and events";
        };

        sprite = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Show the companion as an inline sprite image (kitty graphics protocol) instead of text-only.";
          };
          size = lib.mkOption {
            type = lib.types.int;
            default = 14;
            description = "Sprite width in terminal cells (frames are cropped to her body, so this is her actual on-screen width; height follows her aspect) — bigger number, bigger pet.";
          };
          position = {
            horizontal = lib.mkOption {
              type = lib.types.enum [
                "left"
                "center"
                "right"
              ];
              default = "right";
              description = "Where the sprite (and her status line) sits horizontally in the terminal.";
            };
            vertical = lib.mkOption {
              type = lib.types.enum [
                "above"
                "below"
              ];
              default = "above";
              description = "Whether the sprite renders above or below the input line.";
            };
            offsetX = lib.mkOption {
              type = lib.types.int;
              default = 0;
              description = "Extra cells to nudge the sprite toward the right edge (the sprite carries ~2 cells of invisible transparent padding, so 2-3 tucks her body flush against the edge; negative shifts left).";
            };
          };
          fps = lib.mkOption {
            type = lib.types.int;
            default = 6;
            description = "Frame rate of the pet animation (original webm is 24 fps; frames are sampled every 24/fps-th frame across the full 10s cycle).";
          };
          speed = lib.mkOption {
            type = lib.types.float;
            default = 1.0;
            description = "Playback speed multiplier (2.0 = the animation cycle completes twice as fast).";
          };
        };

      };

      config = lib.mkIf cfg.pet.enable {
        home.file = {
          "${cfg.configDir}/extensions/pi-pet/index.ts".source = extensionFile;
        };

      };
    };

  flake.homeModules.pi-agent-comma =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      cfg = config.programs.pi-coding-agent;

      nixCommaFile = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/reedrw/nix-config/main/home-modules/extra/pi/plugins/nix-comma.ts";
        hash = "sha256-/OSMjoMgRslGlwe1a8meHyOkK0KmsSbu3MqoRGwku5k=";
      };

      bashSpawnHookFile = pkgs.writeText "pi-bash-spawn-hook-extension.ts" ''
        import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
        import { createBashToolDefinition } from "@earendil-works/pi-coding-agent";

        interface SpawnContext {
        	command: string;
        	cwd: string;
        	env: Record<string, string | undefined>;
        }

        export default function (pi: ExtensionAPI) {
        	pi.registerTool(
        		createBashToolDefinition(process.cwd(), {
        			spawnHook: ({ command, cwd, env }) => {
        				const hook = (globalThis as Record<string, unknown>).__nixCommaSpawnHook as
        					| ((ctx: SpawnContext) => { env: Record<string, string | undefined> } | undefined)
        					| undefined;
        				const patched = hook?.({ command, cwd, env });
        				return { command, cwd, env: { ...env, ...(patched?.env ?? {}) } };
        			},
        		}),
        	);
        }
      '';
    in
    {
      options.programs.pi-coding-agent.comma = {
        enable = lib.mkEnableOption "pi nix-comma extension (auto-provisions missing commands from nixpkgs onto the session PATH)";
      };

      config = lib.mkIf cfg.comma.enable {
        home.file = {
          "${cfg.configDir}/extensions/nix-comma/index.ts".source = nixCommaFile;
          "${cfg.configDir}/extensions/bash-spawn-hook.ts".source = bashSpawnHookFile;
        };
      };
    };
}
