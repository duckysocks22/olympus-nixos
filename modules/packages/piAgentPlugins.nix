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

      themes = {
        default = {
          style = "plain";
        };
        minimal = {
          style = "minimal";
        };
        catppuccin = {
          style = "powerline";
          shape = "pill";
          segments = {
            path = {
              bg = "#f38ba8";
              fg = "#1e1e2e";
            };
            branch = {
              bg = "#89b4fa";
              fg = "#1e1e2e";
            };
            model = {
              bg = "#a6e3a1";
              fg = "#1e1e2e";
            };
            tokens = {
              bg = "#94e2d5";
              fg = "#1e1e2e";
            };
            cost = {
              bg = "#89dceb";
              fg = "#1e1e2e";
            };
            context = {
              bg = "#cba6f7";
              fg = "#1e1e2e";
            };
            usage = {
              bg = "#f9e2af";
              fg = "#1e1e2e";
            };
          };
        };
        gruvbox-rainbow = {
          style = "powerline";
          shape = "arrow";
          segments = {
            path = {
              bg = "#fe8019";
              fg = "#282828";
            };
            branch = {
              bg = "#b8bb26";
              fg = "#282828";
            };
            model = {
              bg = "#83a598";
              fg = "#282828";
            };
            tokens = {
              bg = "#8ec07c";
              fg = "#282828";
            };
            cost = {
              bg = "#928374";
              fg = "#282828";
            };
            context = {
              bg = "#ebdbb2";
              fg = "#282828";
            };
            usage = {
              bg = "#d3869b";
              fg = "#282828";
            };
          };
        };
        pastel-powerline = {
          style = "powerline";
          shape = "arrow";
          segments = {
            path = {
              bg = "#f28b82";
              fg = "#202124";
            };
            branch = {
              bg = "#fdd49e";
              fg = "#202124";
            };
            model = {
              bg = "#aecbfa";
              fg = "#202124";
            };
            tokens = {
              bg = "#a8dab5";
              fg = "#202124";
            };
            cost = {
              bg = "#9dd6c4";
              fg = "#202124";
            };
            context = {
              bg = "#b3c9f7";
              fg = "#202124";
            };
            usage = {
              bg = "#f7c1d4";
              fg = "#202124";
            };
          };
        };
        tokyo-night = {
          style = "powerline";
          shape = "arrow";
          segments = {
            path = {
              bg = "#7aa2f7";
              fg = "#1a1b26";
            };
            context = {
              bg = "#292e42";
              fg = "#c0caf5";
            };
            usage = {
              bg = "#24283b";
              fg = "#c0caf5";
            };
          };
        };
      };

      statusLineFile = pkgs.writeText "pi-status-line-extension.ts" ''
        import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
        import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
        import { existsSync, readdirSync, readFileSync, statSync, unlinkSync, writeFileSync } from "node:fs";
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

        interface Seg {
          id: string;
          text: string;
        }

        interface SegColors {
          bg: string;
          fg?: string;
        }

        interface ThemeSpec {
          style: string;
          shape?: string;
          segments?: Record<string, SegColors>;
        }

        const THEMES: Record<string, ThemeSpec> = ${builtins.toJSON themes};
        const DEFAULT_THEME = ${builtins.toJSON cfg.statusLine.theme};
        const STATE_FILE = ${builtins.toJSON (cfg.configDir + "/statusline-theme")};
        const AUTO_THEME = "auto";
        const AUTO_SOFTEN = 0.3;

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

        function hexToRgb(hex: string): number[] {
          const h = hex.replace("#", "");
          return [
            parseInt(h.substring(0, 2), 16),
            parseInt(h.substring(2, 4), 16),
            parseInt(h.substring(4, 6), 16),
          ];
        }

        const CUBE_VALUES = [0, 95, 135, 175, 215, 255];

        function nearestCube(v: number): number {
          let best = 0;
          let bestDist = Infinity;
          for (let i = 0; i < CUBE_VALUES.length; i++) {
            const d = Math.abs(CUBE_VALUES[i] - v);
            if (d < bestDist) {
              bestDist = d;
              best = i;
            }
          }
          return best;
        }

        function rgbTo256(r: number, g: number, b: number): number {
          const cr = nearestCube(r);
          const cg = nearestCube(g);
          const cb = nearestCube(b);
          const gray = Math.round(0.299 * r + 0.587 * g + 0.114 * b);
          const gi = Math.max(0, Math.min(23, Math.round((gray - 8) / 10)));
          const gv = 8 + gi * 10;
          const cubeDist =
            Math.abs(CUBE_VALUES[cr] - r) + Math.abs(CUBE_VALUES[cg] - g) + Math.abs(CUBE_VALUES[cb] - b);
          const grayDist = Math.abs(gv - gray);
          const spread = Math.max(r, g, b) - Math.min(r, g, b);
          if (spread < 10 && grayDist < cubeDist) {
            return 232 + gi;
          }
          return 16 + 36 * cr + 6 * cg + cb;
        }

        function fgAnsi(hex: string, mode: string): string {
          const rgb = hexToRgb(hex);
          if (mode === "256color") {
            return "\x1b[38;5;" + rgbTo256(rgb[0], rgb[1], rgb[2]) + "m";
          }
          return "\x1b[38;2;" + rgb[0] + ";" + rgb[1] + ";" + rgb[2] + "m";
        }

        function bgAnsi(hex: string, mode: string): string {
          const rgb = hexToRgb(hex);
          if (mode === "256color") {
            return "\x1b[48;5;" + rgbTo256(rgb[0], rgb[1], rgb[2]) + "m";
          }
          return "\x1b[48;2;" + rgb[0] + ";" + rgb[1] + ";" + rgb[2] + "m";
        }

        const RESET = "\x1b[0m";

        function varStr(vars: Record<string, any>, key: string): string | null {
          const v = vars[key];
          return typeof v === "string" && v.startsWith("#") ? v : null;
        }

        function relLum(hex: string): number {
          const rgb = hexToRgb(hex).map((v) => {
            const s = v / 255;
            return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
          });
          return 0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2];
        }

        function contrastRatio(a: string, b: string): number {
          const la = relLum(a);
          const lb = relLum(b);
          return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
        }

        function mixHex(a: string, b: string, t: number): string {
          const x = hexToRgb(a);
          const y = hexToRgb(b);
          const c = x.map((v, i) => Math.round(v * (1 - t) + y[i] * t));
          return (
            "#" +
            c
              .map((v) => Math.max(0, Math.min(255, v)).toString(16).padStart(2, "0"))
              .join("")
          );
        }

        function pickFg(bg: string, candidates: (string | null)[]): string {
          const valid = candidates.filter((c): c is string => !!c && c.startsWith("#"));
          let fallback = valid[0] || "#ffffff";
          let fallbackScore = -1;
          let gentlest = fallback;
          let gentlestScore = Infinity;
          for (const c of valid) {
            const score = contrastRatio(bg, c);
            if (score > fallbackScore) {
              fallbackScore = score;
              fallback = c;
            }
            if (score >= 4.5 && score < gentlestScore) {
              gentlestScore = score;
              gentlest = c;
            }
          }
          return gentlestScore !== Infinity ? gentlest : fallback;
        }

        function contrastFg(bg: string, vars: Record<string, any>): string {
          return pickFg(bg, [
            varStr(vars, "fg2"),
            varStr(vars, "fgBright"),
            varStr(vars, "fg"),
            varStr(vars, "text"),
            "#e2dedb",
            varStr(vars, "bg"),
            varStr(vars, "surface"),
            "#101014",
          ]);
        }

        let autoCacheKey: string | null = null;
        let autoCacheSpec: ThemeSpec | null = null;

        function autoSpec(theme: any): ThemeSpec | null {
          try {
            const sp = theme && theme.sourcePath;
            if (!sp || typeof sp !== "string") return null;
            const st = statSync(sp);
            const key = sp + ":" + st.mtimeMs;
            if (key === autoCacheKey) return autoCacheSpec;
            const json = JSON.parse(readFileSync(sp, "utf8"));
            const vars: Record<string, any> = json.vars || {};
            const pick = (names: string[]): string | null => {
              for (const n of names) {
                const v = varStr(vars, n);
                if (v) return v;
              }
              return null;
            };
            const defs: [string, string[]][] = [
              ["path", ["blue", "accent"]],
              ["branch", ["green"]],
              ["model", ["magenta", "purple", "accent"]],
              ["tokens", ["cyan"]],
              ["cost", ["yellow", "orange"]],
              ["context", ["orange", "yellow", "surface2"]],
              ["usage", ["surface2", "surface", "selectedBg", "gray", "red"]],
            ];
            const segments: Record<string, SegColors> = {};
            const softenBase = varStr(vars, "surface") || varStr(vars, "bg");
            for (const def of defs) {
              let bg = pick(def[1]);
              if (bg && softenBase) bg = mixHex(bg, softenBase, AUTO_SOFTEN);
              if (bg) segments[def[0]] = { bg: bg, fg: contrastFg(bg, vars) };
            }
            const spec: ThemeSpec | null =
              Object.keys(segments).length > 0 ? { style: "powerline", shape: "arrow", segments: segments } : null;
            autoCacheKey = key;
            autoCacheSpec = spec;
            return spec;
          } catch (e) {
            autoCacheKey = null;
            autoCacheSpec = null;
            return null;
          }
        }

        let cachedOverride: string | null | undefined = undefined;

        function getOverride(): string | null {
          if (cachedOverride === undefined) {
            let name: string | null = null;
            try {
              if (existsSync(STATE_FILE)) name = readFileSync(STATE_FILE, "utf8").trim();
            } catch (e) {
              name = null;
            }
            if (name && name !== AUTO_THEME && !THEMES[name]) {
              console.error("[pi-status-line] invalid theme in " + STATE_FILE + ": " + name);
              name = null;
            }
            cachedOverride = name || null;
          }
          return cachedOverride;
        }

        function resolveSpec(theme: any): ThemeSpec {
          const name = getOverride() || DEFAULT_THEME;
          if (name === AUTO_THEME) {
            const spec = autoSpec(theme);
            if (spec) return spec;
            return THEMES["default"] || { style: "plain" };
          }
          return THEMES[name] || THEMES["default"] || { style: "plain" };
        }

        interface LineData {
          path: string;
          model: string;
          level: string;
          pct: number | null;
          input: number;
          output: number;
          cost: number;
          branch: string | null;
        }

        function shortenCwd(cwd: string): string {
          const home = process.env.HOME || "";
          if (!home) return cwd;
          if (cwd === home) return "~";
          if (cwd.startsWith(home + "/")) return "~" + cwd.slice(home.length);
          return cwd;
        }

        const fmtTokens = (n: number): string => (n < 1000 ? String(n) : (n / 1000).toFixed(1) + "k");

        function collect(ctx: any, footerData: any): LineData {
          let input = 0;
          let output = 0;
          let cost = 0;
          if (SHOW_TOKENS || SHOW_COST) {
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
          }
          let pct: number | null = null;
          if (SHOW_CONTEXT) {
            const u = ctx.getContextUsage();
            if (u && u.percent !== null && u.percent !== undefined) pct = Math.round(u.percent);
          }
          return {
            path: shortenCwd(String(ctx.cwd || process.cwd() || "")),
            model: ctx.model ? ctx.model.id : "no-model",
            level: String(ctx.thinkingLevel ?? "off"),
            pct: pct,
            input: input,
            output: output,
            cost: cost,
            branch: SHOW_BRANCH ? footerData.getGitBranch() : null,
          };
        }

        function contextBar(pct: number | null): { filled: number; color: string } | null {
          if (pct === null) return null;
          const color = pct < 50 ? "success" : pct < 75 ? "warning" : "error";
          return { filled: Math.min(10, Math.floor((pct + 5) / 10)), color: color };
        }

        function usageText(theme: any): string {
          if (USAGE_LIVE && liveUsage) {
            const now = Date.now();
            return [
              meterLive("5h", liveUsage.rolling, now, theme),
              meterLive("wk", liveUsage.weekly, now, theme),
              meterLive("mo", liveUsage.monthly, now, theme),
            ].join(" ");
          }
          if (USAGE_FIVE_HOUR > 0 || USAGE_WEEKLY > 0 || USAGE_MONTHLY > 0) {
            const now = Date.now();
            const meters: string[] = [];
            if (USAGE_FIVE_HOUR > 0) meters.push(meterStr("5h", usage.d, USAGE_FIVE_HOUR, now, now, theme));
            if (USAGE_WEEKLY > 0) meters.push(meterStr("wk", usage.wk, USAGE_WEEKLY, now, now, theme));
            if (USAGE_MONTHLY > 0) meters.push(meterStr("mo", usage.mo, USAGE_MONTHLY, now, now, theme));
            return meters.filter(Boolean).join(" ");
          }
          return "";
        }

        const noopTheme = { fg: (_c: string, t: string): string => t };

        function renderPlain(d: LineData, theme: any): string {
          const parts: string[] = [];
          if (d.path) parts.push(d.path);
          if (SHOW_MODEL) {
            let levelColor = "dim";
            if (d.level === "low" || d.level === "medium") levelColor = "success";
            else if (d.level === "high" || d.level === "xhigh" || d.level === "max") levelColor = "accent";
            parts.push(theme.fg("accent", "◆ " + d.model) + " " + theme.fg(levelColor, d.level));
          }
          if (SHOW_CONTEXT) {
            const bar = contextBar(d.pct);
            if (!bar) {
              parts.push(theme.fg("dim", "ctx --"));
            } else {
              const filledStr = "█".repeat(bar.filled);
              const emptyStr = "░".repeat(10 - bar.filled);
              parts.push(
                theme.fg("dim", "ctx ") +
                  theme.fg(bar.color, filledStr) +
                  theme.fg("dim", emptyStr) +
                  " " +
                  theme.fg(bar.color, String(d.pct) + "%"),
              );
            }
          }
          if (SHOW_TOKENS || SHOW_COST) {
            const bits: string[] = [];
            if (SHOW_TOKENS) bits.push("↑" + fmtTokens(d.input) + " ↓" + fmtTokens(d.output));
            if (SHOW_COST) bits.push("$" + d.cost.toFixed(2));
            if (bits.length > 0) parts.push(theme.fg("dim", bits.join(" ")));
          }
          if (d.branch) parts.push(theme.fg("warning", d.branch));
          const u = usageText(theme);
          if (u) parts.push(u);
          return parts.join(theme.fg("dim", " | "));
        }

        function renderMinimal(d: LineData): string {
          const parts: string[] = [];
          if (d.path) parts.push(d.path);
          if (SHOW_MODEL) parts.push(d.model + " " + d.level);
          if (SHOW_CONTEXT) parts.push(d.pct === null ? "--" : String(d.pct) + "%");
          if (SHOW_TOKENS || SHOW_COST) {
            const bits: string[] = [];
            if (SHOW_TOKENS) bits.push("↑" + fmtTokens(d.input) + " ↓" + fmtTokens(d.output));
            if (SHOW_COST) bits.push("$" + d.cost.toFixed(2));
            if (bits.length > 0) parts.push(bits.join(" "));
          }
          if (d.branch) parts.push(d.branch);
          const u = usageText(noopTheme);
          if (u) parts.push(u);
          return parts.join("  ");
        }

        function segsFrom(d: LineData): Seg[] {
          const segs: Seg[] = [];
          if (d.path) segs.push({ id: "path", text: d.path });
          if (d.branch) segs.push({ id: "branch", text: d.branch });
          if (SHOW_MODEL) segs.push({ id: "model", text: d.model + " " + d.level });
          if (SHOW_TOKENS) segs.push({ id: "tokens", text: "↑" + fmtTokens(d.input) + " ↓" + fmtTokens(d.output) });
          if (SHOW_COST) segs.push({ id: "cost", text: "$" + d.cost.toFixed(2) });
          if (SHOW_CONTEXT) {
            const bar = contextBar(d.pct);
            segs.push({
              id: "context",
              text: bar
                ? "█".repeat(bar.filled) + "░".repeat(10 - bar.filled) + " " + d.pct + "%"
                : "--",
            });
          }
          const u = usageText(noopTheme);
          if (u) segs.push({ id: "usage", text: u });
          return segs;
        }

        function renderPowerline(d: LineData, spec: ThemeSpec, theme: any): string {
          const mode = theme.getColorMode();
          const colors = spec.segments || {};
          const pill = spec.shape === "pill";
          const segs = segsFrom(d);
          let out = "";
          let prevBg: string | null = null;
          let first = true;
          for (const seg of segs) {
            const c: SegColors | undefined = colors[seg.id];
            if (!c) {
              if (prevBg !== null) {
                out += RESET;
                prevBg = null;
              }
              if (!first) out += " ";
              out += seg.text;
              first = false;
              continue;
            }
            const fgHex = c.fg || pickFg(c.bg, ["#101014", "#f4f4f6"]);
            const bgCode = bgAnsi(c.bg, mode);
            const fgCode = fgAnsi(fgHex, mode);
            const bold = "\x1b[1m";
            let text = seg.text;
            const bar = seg.id === "context" ? contextBar(d.pct) : null;
            if (bar) {
              const emptyHex = mixHex(fgHex, c.bg, 0.45);
              text =
                fgCode +
                bold +
                "█".repeat(bar.filled) +
                fgAnsi(emptyHex, mode) +
                bold +
                "░".repeat(10 - bar.filled) +
                fgCode +
                bold +
                " " +
                d.pct +
                "%";
            }
            if (pill) {
              if (!first) out += " ";
              out +=
                fgAnsi(c.bg, mode) +
                "" +
                RESET +
                bgCode +
                fgCode +
                bold +
                " " +
                text +
                " " +
                RESET +
                fgAnsi(c.bg, mode) +
                "" +
                RESET;
              prevBg = null;
            } else {
              if (prevBg !== null) {
                out += fgAnsi(prevBg, mode) + bgCode + "\uE0B0" + RESET;
              } else if (!first) {
                out += " ";
              }
              out += bgCode + fgCode + bold + " " + text + " " + RESET;
              prevBg = c.bg;
            }
            first = false;
          }
          if (prevBg !== null) {
            out += fgAnsi(prevBg, mode) + "\uE0B0" + RESET;
          }
          return out;
        }

        export default function (pi: ExtensionAPI) {
          let footerTui: { requestRender(force?: boolean): void } | undefined;
          let usageTimer: ReturnType<typeof setInterval> | null = null;
          let lastCtx: any = null;
          let lastData: LineData | null = null;

          function previewLines(theme: any, fallbackModel: string, fallbackLevel: string): string[] {
            const base: LineData = lastData || {
              path: shortenCwd(process.cwd()),
              model: fallbackModel,
              level: fallbackLevel,
              pct: 42,
              input: 12400,
              output: 3200,
              cost: 0.42,
              branch: "main",
            };
            const lines: string[] = [];
            const rows: [string, ThemeSpec][] = [["current", resolveSpec(theme)]];
            for (const n of Object.keys(THEMES)) rows.push([n, THEMES[n]]);
            for (const row of rows) {
              lines.push(theme.fg("dim", row[0] + ":"));
              let line: string;
              if (row[1].style === "powerline") line = renderPowerline(base, row[1], theme);
              else if (row[1].style === "minimal") line = renderMinimal(base);
              else line = renderPlain(base, theme);
              lines.push("  " + line);
              lines.push("");
            }
            return lines;
          }

          pi.registerCommand("statusline", {
            description: "Switch the status line theme (themes | <name> | reset | clear)",
            handler: async (args, ctx) => {
              const sub = args.trim().split(/\s+/)[0] || "themes";
              if (sub === "themes" || sub === "list") {
                ctx.ui.setWidget("pi-status-line-preview", (tui: any, theme: any) => ({
                  invalidate() {},
                  render(width: number): string[] {
                    const lines = previewLines(
                      theme,
                      ctx.model ? ctx.model.id : "model",
                      String((ctx as any).thinkingLevel ?? "high"),
                    );
                    return lines.map((l) => truncateToWidth(l, width));
                  },
                }));
                ctx.ui.notify("Previewing themes — /statusline <name> to apply, /statusline clear to hide", "info");
                return;
              }
              if (sub === "clear" || sub === "hide") {
                ctx.ui.setWidget("pi-status-line-preview", undefined);
                return;
              }
              if (sub === "reset") {
                try {
                  if (existsSync(STATE_FILE)) unlinkSync(STATE_FILE);
                } catch (e: any) {
                  ctx.ui.notify("statusline: cannot delete state file: " + String(e), "error");
                  return;
                }
                cachedOverride = null;
                footerTui?.requestRender();
                ctx.ui.setWidget("pi-status-line-preview", undefined);
                ctx.ui.notify("Status line theme reset to nix default (" + DEFAULT_THEME + ")", "info");
                return;
              }
              if (sub === AUTO_THEME || THEMES[sub]) {
                try {
                  writeFileSync(STATE_FILE, sub);
                } catch (e: any) {
                  ctx.ui.notify("statusline: cannot write state file: " + String(e), "error");
                  return;
                }
                cachedOverride = sub;
                footerTui?.requestRender();
                ctx.ui.setWidget("pi-status-line-preview", undefined);
                ctx.ui.notify("Status line theme: " + sub, "info");
                return;
              }
              ctx.ui.notify("Unknown status line theme: " + sub + " — try /statusline themes", "error");
            },
          });

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
                  const data = collect(ctx, footerData);
                  lastData = data;
                  const spec = resolveSpec(theme);
                  let line: string;
                  if (spec.style === "powerline") line = renderPowerline(data, spec, theme);
                  else if (spec.style === "minimal") line = renderMinimal(data);
                  else line = renderPlain(data, theme);
                  return [truncateToWidth(line, width) + (spec.style === "powerline" ? RESET : "")];
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

        theme = lib.mkOption {
          type = lib.types.enum [
            "auto"
            "default"
            "minimal"
            "catppuccin"
            "gruvbox-rainbow"
            "pastel-powerline"
            "tokyo-night"
          ];
          default = "auto";
          description = ''
            Status line theme. "auto" derives powerline segment colors from the
            active pi theme (e.g. the Stylix-generated stylix.json), so the line
            follows /theme automatically. At runtime, /statusline <theme>
            overrides this value by writing ${cfg.configDir}/statusline-theme
            (not home-manager managed); /statusline reset deletes that file and
            returns to this option's value.
          '';
        };

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
                -pix_fmt rgba -fps_mode passthrough \
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

  flake.homeModules.pi-agent-skills =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      cfg = config.programs.pi-coding-agent;

      skillFiles = {
        commit-message = pkgs.writeText "commit-message-SKILL.md" ''
          ---
          name: commit-message
          description: "Reviews working-tree changes, then drafts a Conventional Commits title/body and states the semantic-release version bump a single such commit would imply. Use when the user wants to commit recent work, prepare a Conventional Commits message, or asks for semantic-release / semver-consistent messaging before git commit."
          ---

          # Commit Message

          > **HARD GATE** — Commits must follow Conventional Commits spec (type(scope): description). Do NOT use vague messages like 'fix' or 'updates.' The message must explain the 'why,' not the 'what.'

          ## Modes

          - Default: standard Conventional Commits message
          - --fix-type: Forces type=fix. Use when commit type is unambiguous.

          ## Sources

          - **Primary source of truth:** `git status`, `git diff`, and `git diff --cached` run in the repo root.
          - **Context:** use the current conversation to summarize *intent* and to spot **breaking** API/behavior changes that diff alone may not show.
          - If the user tracks a session baseline (branch, tag, or `git stash create` at start), you may diff against it; otherwise use only the index and working tree.

          ## Workflow

          1. **Inventory** — List changed paths; group by feature vs chore vs docs vs test-only.
          2. **Decide commit shape** — One atomic commit is ideal. If the diff mixes unrelated concerns, recommend **multiple commits** (each with its own type/scope) before suggesting one message.
          3. **Classify for semantic release** — `fix` → patch, `feat` → minor, **breaking** → major.
          4. **Write the message** — `type(optional-scope)!: description`. Use `!` or a `BREAKING CHANGE:` footer when behavior contracts change.
          5. **Note defensive-code categories touched** — Rate limit | Retry with backoff | Circuit breaker | Timeout | Graceful degradation.
          6. **Deliver** — Output:
             - Proposed **full commit message** (title + optional body + footers).
             - **Release bump** this commit would drive: `patch` | `minor` | `major` | `none`.
             - Optional native command: `git commit -m`. Never omit `-m`; never run commit or destructive git commands unless the user explicitly asked in that message.

          ## Checklist before finalizing

          - [ ] Type matches the **dominant** user-visible outcome (`feat` vs `fix` vs `perf`, etc.).
          - [ ] **Scope** is a short noun in parentheses if it helps (e.g. `fix(api): …`).
          - [ ] Breaking changes are explicit (`!` and/or `BREAKING CHANGE:` in the body/footer).
          - [ ] Description is imperative, lowercase start after the prefix, no trailing period in the title line.
          - [ ] **NO `Co-authored-by` or `Co-Authored-By` footers** — all commits must appear as if authored solely by the human user.

          ## When not to invent a bump

          If the repo uses a custom `@semantic-release/commit-analyzer` preset, note that your bump is **heuristic** and the user should match `.releaserc` / `release.config.*`.

          ---

          # Conventional Commits + semantic-style release (reference)

          ## Message format

          From [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/#specification):

          ```text
          <type>[optional scope][optional !]: <description>

          [optional body]

          [optional footer(s)]
          ```

          - **Scope:** parenthesized noun, e.g. `feat(parser): …`.
          - **Breaking:** `!` before `:` (e.g. `feat(api)!: …`) and/or footer `BREAKING CHANGE: description` (token must be uppercase per spec for that footer name).
          - **Description:** short summary; body explains *why* or migration steps.

          Common **types** (not exhaustive): `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore` — as in [Angular / commitlint conventions](https://github.com/conventional-changelog/commitlint).

          ### Reverts

          If the commit reverts a previous commit, it should begin with `revert:`, followed by the header of the reverted commit. In the body, it should say: `This reverts commit <hash>.`

          ### Breaking Changes

          A breaking change can be signaled by:
          1. A `BREAKING CHANGE:` footer (must be uppercase, at the start of the footer). This is the **most compatible** way to trigger a Major release in `semantic-release` (Angular preset).
          2. A `!` after the type/scope: `feat(api)!: change user response shape`.

          **Pro-tip:** For maximum compatibility with all tooling, use BOTH the `!` and the `BREAKING CHANGE:` footer.

          ### Footers (Tokens & Values)

          Footers follow the same `Token: value` pattern as Git Trailers. Common tokens: `Refs: #123`, `See-also: docs/ADR-001.md`, `Signed-off-by: Name <email>`.

          **Multi-line footers:** If a footer value spans multiple lines, each subsequent line must be indented.

          ## Release Type Mapping (Default Angular Preset)

          | Commit pattern | Release | Notes |
          |----------------|---------|-------|
          | `fix:` | **Patch** | Bug fixes |
          | `feat:` | **Minor** | New features |
          | `perf:` | **Patch** | Performance improvements |
          | `any type` + `BREAKING CHANGE:` footer | **Major** | **Mandatory** for Major version bumps in default configs. |
          | `any type!:` (exclamation mark) | **Major** | Supported by modern CC parsers, but use footer for max safety. |
          | `docs:`, `chore:`, `test:`, `ci:`, `refactor:`, `style:` | **None** | Does not trigger a new release by default. |

          > **Warning:** While `refactor:` and `style:` improve code, they do NOT trigger a release in the default Angular preset. Use `fix:` if a refactor also fixes a bug, or `feat:` if it adds new behavior.

          ## Squash and PR titles

          If the team squashes on merge, the **PR title** often becomes the single squashed commit subject — it should still follow `type(scope): description` for tooling.
        '';

        investigate-bug = pkgs.writeText "investigate-bug-SKILL.md" ''
          ---
          name: investigate-bug
          description: "Investigate a bug or issue by exploring the codebase to find root cause, then write a TDD-based fix plan to specs/bugs/BUG-*.md. Use when user reports a bug, wants to investigate a problem, mentions \"triage\", or wants to plan a fix."
          ---

          # Investigate Bug

          **Boundary**: End-to-end bug entry point — history check → RCA (via `diagnose-root`) → fix approach → TDD plan → bug file. Delegates the 4-phase RCA to `diagnose-root`; does not re-implement it.

          Investigate a reported problem, find its root cause, and write a TDD fix plan to `specs/bugs/BUG-*.md`. This is a mostly hands-off workflow — minimize questions to the user.

          ## Process

          ### 0. Read previous bug history

          Before starting diagnosis:

          1. Read `specs/bugs/registry.yaml` (if it exists) — check for prior bugs in the same `scope` or with similar symptoms.
          2. If a relevant prior bug is found, read the corresponding `specs/bugs/BUG-*.md` file to understand previous root cause analysis and fix approach.
          3. Note in your investigation whether this is a recurrence, a related issue, or novel.

          ### 1. Capture the problem

          Get a brief description of the issue from the user. If they haven't provided one, ask ONE question: "What's the problem you're seeing?"

          Do NOT ask follow-up questions yet. Start investigating immediately.

          > **Security-impact assessment** — After capturing the problem, assess and document: `Security impact: NONE / LOW / MEDIUM / HIGH / CRITICAL`. If HIGH or CRITICAL, assign bug severity HIGH and document the exploit path in findings. Document "no security exploit path identified" for NONE/LOW.

          ### 2. Explore and diagnose (4-phase RCA)

          Run the 4-phase root-cause analysis via the `diagnose-root` skill (Reproduce → Isolate → Hypothesize → Verify). That skill is the canonical RCA engine — do not re-implement the phases here.

          Also look at:
          - Recent changes to affected files (`git log --oneline <file>`)
          - Existing tests (what's tested, what's missing)
          - Similar patterns elsewhere in the codebase that work correctly

          > **HARD GATE** — Do NOT proceed to Step 3 (Fix Approach) until `diagnose-root` Phase 4 produces a verified root cause. "It probably is X" is not verified.

          ### 3. Identify the fix approach

          Based on your investigation, determine:

          - The minimal change needed to fix the root cause
          - Which modules/interfaces are affected
          - What behaviors need to be verified via tests
          - Whether this is a regression, missing feature, or design flaw
          - Risk level: Low / Medium / High

          ### 4. Design TDD fix plan

          Create a concrete, ordered list of RED-GREEN cycles. Each cycle is one vertical slice:

          - **RED**: Describe a specific test that captures the broken/missing behavior
          - **GREEN**: Describe the minimal code change to make that test pass

          Rules:
          - Tests verify behavior through public interfaces, not implementation details
          - One test at a time, vertical slices (NOT all tests first, then all code)
          - Each test should survive internal refactors
          - Include a final refactor step if needed
          - **Durability**: Only suggest fixes that would survive radical codebase changes. Tests assert on observable outcomes (API responses, UI state, user-visible effects), not internal state.

          ### 5. Write the bug file

          Save the investigation and fix plan to `specs/bugs/BUG-NNN-slug.md`. Create the `specs/bugs/` directory if it doesn't exist.

          After writing, append a row to `specs/bugs/registry.yaml` with: bug_id (same timestamp), date, severity, priority, scope, summary, and file path. Create `specs/bugs/registry.yaml` if it doesn't exist.

          <diagnosis-template>

          # BUG-YYYY-MM-DDTHHMMSS: [short title]

          ## Problem

          A clear description of the bug or issue, including:
          - What happens (actual behavior)
          - What should happen (expected behavior)
          - How to reproduce (if applicable)

          ## Root Cause Analysis

          Describe what you found during investigation:
          - The code path involved
          - Why the current code fails
          - Any contributing factors
          - Risk level: Low / Medium / High

          Do NOT include specific file paths, line numbers, or implementation details that couple to current code layout. Describe modules, behaviors, and contracts instead.

          ## TDD Fix Plan

          A numbered list of RED-GREEN cycles:

          1. **RED**: Write a test that [describes expected behavior]
             **GREEN**: [Minimal change to make it pass]
             **verify**: [runnable command]

          2. **RED**: Write a test that [describes next behavior]
             **GREEN**: [Minimal change to make it pass]
             **verify**: [runnable command]

          **REFACTOR**: [Any cleanup needed after all tests pass]

          ## Acceptance Criteria

          - [ ] Criterion 1
          - [ ] Criterion 2
          - [ ] All new tests pass
          - [ ] Existing tests still pass

          ## Resolution

          <!-- filled in by validate-fix -->

          </diagnosis-template>

          After writing the bug file, print a one-line summary of the root cause and suggest creating a fix branch before implementing.
        '';

        diagnose-root = pkgs.writeText "diagnose-root-SKILL.md" ''
          ---
          name: diagnose-root
          description: "Run 4-phase root cause analysis — reproduce, isolate, hypothesize, verify. Use when a bug is confirmed but root cause is unclear, after investigate-bug, or when user mentions root cause analysis."
          ---

          # Diagnose Root

          **Boundary**: Canonical, reusable 4-phase RCA engine. Invoked by `investigate-bug` as step 2 of the end-to-end flow. Does not write the bug file — that is `investigate-bug`'s responsibility.

          Four phases — do not skip. Update the active `specs/bugs/BUG-*.md` file at each phase (if one exists).

          ## Phases

          1. **Reproduce** — minimal steps; record environment; capture logs.
          2. **Isolate** — narrow to module/function; binary-search commits or config.
          3. **Hypothesize** — list ranked hypotheses with falsification test each.
          4. **Verify** — run falsification; confirm single root cause; link to fix plan.

          > **HARD GATE** — Do not propose a fix until phase 4 confirms one root cause with evidence.
        '';

        validate-fix = pkgs.writeText "validate-fix-SKILL.md" ''
          ---
          name: validate-fix
          description: "Prove a fix works before declaring done — re-run the failing test, run the full suite, typecheck, lint, and harden against recurrence. Use after implementing a bug fix, when user says \"is this fixed?\", or before closing an investigation."
          ---

          # Validate Fix

          > **HARD GATE** — Fix must not regress. Run full test suite and manual verification before declaring success.

          Prove the fix works. "I think it works" is not evidence. Run the suite, show the output, then harden against recurrence.

          > **Two-commit red/green policy** — Bug fixes follow two-commit discipline: first commit adds/adjusts the failing test (`test(<scope>): …`), second commit applies the fix (`fix(<scope>): …`). Do not squash RED and GREEN before review.

          ## Checklist

          ### 1. Re-run the originally failing test

          ```bash
          # Run the specific test that captured the bug
          <test command for the failing test>
          ```

          - [ ] Previously failing test now passes

          ### 2. Run the full test suite

          ```bash
          # Run all tests — no filtering
          <full test command>
          ```

          - [ ] All tests pass (zero regressions)

          ### 3. Type check

          ```bash
          <typecheck command>
          ```

          - [ ] No type errors introduced

          ### 4. Lint

          ```bash
          <lint command>
          ```

          - [ ] No lint violations introduced

          ### 5. Harden against recurrence

          For every bug fixed, add at least one prevention layer:

          | Mechanism | When to use |
          |-----------|-------------|
          | Type guard | Input could be the wrong shape |
          | Schema validation | External data crossing a boundary |
          | Invariant assertion | Internal state that must always hold |
          | Lint rule | Pattern that's easy to repeat by mistake |
          | Environment check at startup | Missing config causes silent failure |

          - [ ] At least one hardening mechanism added
          - [ ] Hardening mechanism is tested

          ### 6. Generalize-fix

          Sweep the **defect class** across the codebase after local hardening:

          1. **Classify** — name the pattern (e.g. `unscoped query`, `fail-open verify`, `hardcoded path`).
          2. **Sweep** — grep for sibling instances; record `match_count` and `grep_pattern`.
          3. **Resolve** — patch all matches in this change **or** file one tracking item listing every remaining instance.

          ### 7. Update the bug file

          If `specs/bugs/BUG-*.md` exists for this fix, append the resolution:

          ```markdown
          ## Resolution

          **Fixed:** [date]
          **Root cause confirmed:** [one sentence]
          **Fix applied:** [what was changed]
          **Hardening added:** [type guard / schema / assertion / lint rule]
          **Evidence:** all tests pass (`<verify command>`)
          **Commit:** `fix(<scope>): <description>`
          ```

          ### 8. Behavioral Proof (HARD GATE)

          Mechanical verification (tests passing) is only half the fix. You must prove **behavioral correctness**.

          - [ ] Manually demonstrate the fixed behavior
          - [ ] Compare the output/state against the expected behavior from the bug report
          - [ ] Show the user evidence of the behavior, not just the test logs

          ## Rules

          - **Loop until behavioral correctness is verified**: if any checklist item fails, or if the behavior is still incorrect despite passing tests, return to step 1 and run all checks again from the top — do not declare done until every item is green and the behavior is proven correct in a single run.
          - **Never use `@ts-ignore`, `as any`, or lint-disable comments** to "fix" a bug — these suppress the symptom without fixing the root cause
          - **Never mark the task done if any test is still failing**

          Suggest next skill: `commit-message`.
        '';

        organize-workspace = pkgs.writeText "organize-workspace-SKILL.md" ''
          ---
          name: organize-workspace
          description: "Scans the active workspace for disposable artifacts—logs, caches, stale build output, and stray draft markdown—and proposes consolidation of scattered assets. Produces a reviewable list, asks for explicit confirmation before any delete or move, and optionally revises .gitignore. Use when the user says \"clean my room\", \"organize workspace\", \"workspace cleanup\", \"remove temp files\", \"organize assets\", \"gitignore\", or wants a safe tidy pass."
          ---

          # Organize Workspace

          > **HARD GATE** — Workspace structure must reflect domain structure. If the codebase feels disorganized, flag it. Disorganization != 'just a style thing;' it is a signal of domain misalignment.

          ## Principles

          - **Read-only first**: inventory and size (`du`, `ls -la`) before any change.
          - **Never delete or move** without a numbered list and **explicit user approval** (item-level or "approve all").
          - **Prefer `fd` / `ripgrep` / `find`** in that order; avoid blind `rm -rf` on vague globs.
          - **Do not** touch `.git/`, `node_modules/`, `venv/`, `.env*`, or SSH keys; flag them only if the user asked about them.
          - Confirm prompts in the **user's language** if they are not writing in English.

          ## 1. Establish scope

          - Default: **current project root** (where the user is working) or the path they name.
          - Record OS for ignore patterns (e.g. `.DS_Store`).

          ## 2. Classify candidates (scan)

          Group findings under these **buckets**:

          | Bucket | Examples | Typical action |
          |--------|----------|----------------|
          | **Logs & temp** | `*.log`, `logs/`, `tmp/`, `temp/`, `*.pid` | Delete after confirm |
          | **Build / cache** | `dist/`, `build/`, `.next/`, `coverage/`, `.turbo/` | Delete if rebuildable |
          | **Package caches** | root `.cache/`, `__pycache__/` | Offer delete |
          | **Stray drafts** | root-level `*.md` named `draft`, `scratch`, `temp` | User picks: delete, move, or keep |
          | **Duplicate / dump dirs** | `old/`, `backup/`, `copy/`, `*_backup` | List + ask |

          Use quick size hints: `du -sh` per top-level dir; sort large items first.

          ## 3. Assets & data (organize, not only delete)

          If the user wants **organization**:

          1. Propose a **single convention**, e.g.:
             - `assets/` — images, fonts, static media
             - `data/` — JSON, CSV, fixtures, samples
             - `specs/` — all planning and domain documents
          2. For each cluster of loose files, suggest **one target path** and a short rationale.
          3. Use **git-aware moves** when in a repo: `git mv` if tracked; otherwise `mv` and report.
          4. Never move secrets or production DB dumps into `docs/` or public `assets/`.

          ## 4. Present the plan

          Output a table or numbered list:

          - Path
          - Kind (log / build / draft / asset / other)
          - Approx size
          - Proposed action: **delete** | **move to …** | **keep**

          Ask: *"Delete items 1–3? Move 4–5? Skip 6?"*

          ## 5. Execute after approval

          - Deletes: prefer a Trash-capable tool if installed; else `rm` with paths echoed back.
          - Moves: create dirs with `mkdir -p` first; one batch at a time.
          - **Verify**: re-run listing on affected parents; if anything failed, report stderr.

          ## 6. Post-cleanup and `.gitignore` revision

          Do this when the repo is under Git and the cleanup surfaced **untracked** noise:

          1. **Inventory ignore sources**: root `.gitignore`, `.git/info/exclude`, any subpackage `.gitignore` files.
          2. **Map findings to rules**: for each deleted or recurring artifact class, check whether a pattern already exists; note gaps.
          3. **Propose a patch**: list only **concrete** changes — `+` add / `-` remove / `~` reword — with one-line why.
          4. **User must approve** the exact diff before editing the file.
          5. **Verify**: run `git check-ignore -v <path>` on 2–3 representative paths.

          ---

          # Reference patterns

          Optional commands. Adapt paths; **dry-run** before bulk delete.

          ## Discover large top-level entries

          ```sh
          du -sh ./* .[!.]* 2>/dev/null | sort -hr | head -30
          ```

          ## Find common logs (respect .gitignore when using fd)

          ```sh
          fd -t f '\.log$' . 2>/dev/null
          fd 'npm-debug' . 2>/dev/null
          ```

          ## Find build-like dirs (review list before rm -rf)

          ```sh
          fd -t d '^(dist|build|out|target|\.next|coverage)$' . --max-depth 3 2>/dev/null
          ```

          ## Stray markdown at repo root (heuristic)

          ```sh
          ls -1 ./*.md 2>/dev/null
          fd -t f '^(draft|scratch|untitled|TODO|notes)' . --max-depth 1 2>/dev/null
          ```

          ## Git-safe moves

          ```sh
          git status -sb
          git check-ignore -v <path>   # was ignored?
          # Tracked: git mv old new
          # Untracked: mkdir -p … && mv old new
          ```

          ## .gitignore revision (after cleanup)

          **Goal:** stop regenerated junk from polluting `git status`, without hiding real source.

          1. **Read** root `.gitignore` and, in monorepos, nested `.gitignore` files as needed. Check **`.git/info/exclude`** for machine-only rules that should *not* be committed.
          2. **Per-path checks** (last match wins; shows which file defined the rule):

             ```sh
             git check-ignore -v path/to/artifact
             git status -u --ignored    # optional: see ignored names (noisy)
             ```

          3. **Pattern style**
             - Leading `/` = relative to the `.gitignore`'s directory (e.g. `/dist/` = only that folder at that level, not all nested `dist` unless intended).
             - `**` for deep trees, e.g. `**/*.log`, when noise appears at many depths.
             - **Negation** (`!`) is tricky: later rules, parent dirs, and `git add -f` interact—prefer narrow positive ignores over `!` unless you already use negation in this file.
          4. **Do not** add rules that would ignore: application source, small JSON/YAML config the repo tracks, or important assets. When unsure, run `git check-ignore -v` on a *known good* file that must stay tracked.
          5. **Tracked but should be ignored** (user already committed `build/` once): this skill does not silently fix history; flag `git rm -r --cached <path>` + `.gitignore` as a **separate** explicit step the user must approve.
          6. **Global excludes** (optional heads-up for "why is this still ignored?"):

             ```sh
             git config --get core.excludesfile
             ```

          ## Safety: never pass through these in automated deletes

          - `.git/`, `.svn/`, `.hg/`
          - `node_modules/`, `vendor/`, `venv/`, `.venv/`, `__pypackages__/`
          - Files matching `.env`, `.env.*` (except `.env.example` if intentional)
          - `~/.ssh`, `id_rsa*`, `*.pem` inside project trees

          ## Post-deploy / server-ish extras (name buckets to stack)

          - Docker: dangling images/volumes (only if user asked for Docker cleanup; requires `docker` context).
          - CI: `*.log` under `build/`, artifact dirs from previous runs.
          - K8s: local `*.kube`, tmp kubeconfigs—list only; do not delete without confirmation.
        '';

        security-review = pkgs.writeText "security-review-SKILL.md" ''
          ---
          name: security-review
          description: "AI-powered security analysis of code changes — traces data flow, detects injection, auth bypass, secrets exposure, and unsafe deserialization across files. Use when reviewing pending changes, before merging a feature branch, or when the user says \"security review\" or \"scan for vulns\"."
          ---

          # Security Review

          > **HARD GATE** — Requires git context (branch with merge-base or diff). Findings below confidence 8/10 are suppressed. Pre-flight: `git rev-parse HEAD >/dev/null 2>&1`

          ## 5-phase scan

          | # | Phase | What |
          |---|-------|------|
          | 1 | **Scope Resolution** | Detect diff via `git diff --merge-base origin/HEAD`; resolve languages/frameworks from dependency files |
          | 2 | **Context Research** | Identify existing security patterns, sanitization, auth model in the codebase |
          | 3 | **Vulnerability Assessment** | Trace user input → sink; check auth boundaries, crypto, deserialization, path ops |
          | 4 | **False-Positive Filtering** | Cross-check each finding against exclusion rules; reject confidence < 8 |
          | 5 | **Report Generation** | Output structured markdown: file:line, severity, category, exploit scenario, fix |

          ## Categories

          Covered: SQLi, XSS, SSRF, command injection, auth bypass, unsafe deserialization, path traversal, IDOR, crypto flaws, secrets exposure, template injection, NoSQLi

          ## SQL-safety doctrine

          Formal rule for SQL injection classification:

          | SQL source | Attacker-reachable input? | Verdict |
          |------------|---------------------------|---------|
          | Hardcoded / compile-time constant string | N/A | **Safe** — proven authorship |
          | Developer-authored query with bound parameters only | No dynamic fragments from user input | **Safe** |
          | String concatenation / template with user-controlled values | Yes | **Unsafe** — report as SQLi |
          | ORM query builder with user input in WHERE/JOIN | Yes | **Unsafe** unless parameterized |
          | Stored procedure call with bound args | Args from trusted constants only | **Safe** |
          | Stored procedure with dynamic SQL inside | User input reaches EXEC | **Unsafe** |

          **Provenance test:** If the agent cannot prove the query string was authored entirely by the developer (no attacker-reachable interpolation), treat as vulnerable. Hardcoded SQL in migrations, seeds, and admin scripts is safe; anything reachable from HTTP/CLI/user input is not.

          ## Report format

          Each finding: **`File:Line` — Severity — Category**
          - Description: how the vulnerability manifests
          - Exploit scenario: concrete attack path
          - Recommendation: fix with code example

          ---

          # Confidence Scoring Rubric

          Every finding that survives Phase 4 false-positive filtering receives a confidence score from 1 (speculative) to 10 (certain). Only findings ≥ 8 are reported.

          ## Score 9–10: Certain Exploit Path

          **Criteria:**
          - Concrete, testable exploit with clear reproduction steps
          - No assumptions about uncommon configurations
          - No chain of multiple unlikely conditions
          - Attacker has full control over the input vector

          **Examples:**
          - User-supplied SQL in a `SELECT` statement with no parameterization
          - `os.system(f"rm {user_path}")` where user controls the path
          - Pickle deserialization of user-supplied data without any wrapping

          **Severity:** HIGH

          ## Score 8: Clear Vulnerability Pattern

          **Criteria:**
          - Well-known vulnerability pattern with standard exploitation method
          - Requires specific conditions but conditions are commonly met
          - Exploitability is well-documented in OWASP / CVE databases

          **Examples:**
          - JWT without signature verification in authentication middleware
          - SSRF where attacker controls the full URL including host
          - Hardcoded AWS secret key in source code

          **Severity:** HIGH or MEDIUM

          ## Score 7: Suspicious Pattern

          **Criteria:**
          - Unusual code that may indicate a vulnerability
          - Requires specific conditions that may not be present
          - Alternative secure interpretation is equally likely
          - Defense-in-depth concern rather than direct exploit

          **Examples:**
          - A function accepting user input that passes through multiple layers before reaching a sink (unclear if sanitized)
          - Custom encryption implementation (likely weak, but may not process sensitive data)
          - Path construction that looks safe but has a subtle bypass

          **Severity:** LOW or suppress

          ## Score < 7: Do Not Report

          **Criteria:**
          - Theoretical concern without exploit path
          - Requires unrealistic attacker capabilities
          - Violates one or more hard exclusion rules
          - Better handled by separate tooling (dependency scanner, SAST, secret scanner)
          - Purely stylistic or best-practice concern without security impact

          **Action:** Suppress entirely. Do not include in report.

          ## Severity Mapping

          Once confidence ≥ 8 is confirmed, map to severity:

          | Severity | Impact | Examples |
          |----------|--------|----------|
          | **CRITICAL** | Remote compromise, full data breach | RCE, auth bypass with admin escalation, SQLi with data exfiltration |
          | **HIGH** | Significant security boundary crossed | SSRF to internal services, hardcoded cloud credentials, insecure deserialization |
          | **MEDIUM** | Limited impact or requires conditions | Stored XSS behind auth, IDOR on non-sensitive data, weak but not broken crypto |
          | **LOW** | Defense-in-depth, minimal blast radius | Missing security header, verbose error messages in non-production |

          ## Quality Gate

          The confidence rubric double-checks each finding against three lenses:

          | Lens | Question |
          |------|----------|
          | **Exploitability** | Can a real attacker trigger this from a trust boundary? |
          | **Actionability** | Would a security engineer accept a fix recommendation for this? |
          | **Precedent** | Has this type of finding passed/failed human review before? |

          ---

          # False-Positive Exclusion Rules

          Applied during Phase 4 of the scan. Findings matching any hard exclusion are automatically suppressed. Precedents from prior reviews guide borderline cases.

          ## Hard Exclusions

          Automatically exclude findings matching these patterns:

          | # | Rule | Rationale |
          |---|------|-----------|
          | 1 | **Denial of Service (DOS)** — resource exhaustion, CPU/memory attacks | Handled separately; not actionable in code review |
          | 2 | **Secrets on disk** if otherwise secured | Secrets management is a separate concern |
          | 3 | **Rate limiting** concerns | Operational, not a code vulnerability |
          | 4 | **Memory consumption / CPU exhaustion** | Not actionable in diff review |
          | 5 | **Input validation on non-security-critical fields** without proven exploit path | Theoretical, not concrete |
          | 6 | **GitHub Actions input sanitization** unless clearly triggerable via untrusted input | Most workflow vulns are not exploitable |
          | 7 | **Lack of hardening measures** | Code is not expected to implement all best practices |
          | 8 | **Race conditions / timing attacks** that are theoretical | Only report if concretely problematic |
          | 9 | **Outdated third-party libraries** | Managed separately by dependency scanners |
          | 10 | **Memory safety** in Rust or other memory-safe languages | Impossible by language guarantees |
          | 11 | **Hardcoded SQL with proven authorship** — migrations, seeds, static admin queries with no user interpolation | Developer-authored SQL is safe per SQL-safety doctrine |
          | 12 | **Unit test files only** | Not production risk |
          | 13 | **Log spoofing** | Outputting unsanitized input to logs is not a vuln |
          | 14 | **SSRF that only controls path** | Only host/protocol control is exploitable |
          | 15 | **User-controlled content in AI system prompts** | Not a security vulnerability |
          | 16 | **Regex injection** | Injecting untrusted content into regex is not a vuln |
          | 17 | **Regex DOS** | Excluded alongside general DOS |
          | 18 | **Documentation files** (.md, .txt) | Insecure docs are not code vulnerabilities |
          | 19 | **Lack of audit logs** | Not a vulnerability |

          ## Precedent Rules

          These guide borderline cases based on prior human review decisions:

          | # | Precedent | Reasoning |
          |---|-----------|-----------|
          | 1 | **Logging high-value secrets in plaintext IS a vuln.** Logging URLs is safe. | Secrets in logs = credential exposure; URLs are not secrets |
          | 2 | **UUIDs are unguessable** — no validation needed | Cryptographic property of UUID v4/v7 |
          | 3 | **Environment variables and CLI flags are trusted values** | Attackers cannot modify these in secure environments |
          | 4 | **Resource management issues** (memory leaks, fd leaks) are NOT valid | Operational, not security |
          | 5 | **Tabnabbing, XS-Leaks, prototype pollution, open redirects** — do NOT report unless extremely high confidence | Subtle, low-impact, high false-positive rate |
          | 6 | **React/Angular XSS** — safe unless `dangerouslySetInnerHTML`, `bypassSecurityTrustHtml`, etc. | Framework auto-escapes |
          | 7 | **GitHub Action workflow vulns** — verify concrete attack path before reporting | Most are theoretical |
          | 8 | **Client-side JS/TS auth checks** — not a vuln; server is authoritative | Client code is untrusted |
          | 9 | **IPython notebook vulns** — only report if concrete untrusted-input trigger | Most are not exploitable |
          | 10 | **Logging non-PII data** — not a vuln even if sensitive. Only PII/secrets/passwords. | Intent: operational logging vs credential exposure |
          | 11 | **Shell script command injection** — only report if concrete untrusted-input path | Most shell scripts don't process untrusted input |

          ## Confidence Scoring

          Findings that survive exclusions get a confidence score (1–10):

          | Range | Meaning | Action |
          |-------|---------|--------|
          | 9–10 | Certain exploit path, testable | Report as HIGH |
          | 8 | Clear vulnerability pattern | Report as HIGH/MEDIUM |
          | 7 | Suspicious, needs conditions | Report as LOW or suppress |
          | <7 | Too speculative | **Do not report** |

          **Hard threshold:** Only report findings with confidence ≥ 8.

          ## Signal Quality Criteria

          For remaining findings, assess:
          1. Is there a concrete, exploitable vulnerability with a clear attack path?
          2. Does this represent a real security risk (vs theoretical best practice)?
          3. Are there specific code locations and reproduction steps?
          4. Would this finding be actionable for a security team?

          ---

          # Vulnerability Categories — Detection Guidance

          Each category: vulnerable pattern → safe pattern → code example.

          ## SQL Injection

          | Aspect | Detail |
          |--------|--------|
          | **Vulnerable** | String interpolation in SQL queries: `f"SELECT * FROM users WHERE id = {uid}"` |
          | **CWE** | CWE-89 (SQL Injection) |
          | **Safe** | Parameterized queries / ORM: `cursor.execute("SELECT * FROM users WHERE id = %s", (uid,))` |
          | **Look for** | f-strings, `+` concatenation, `format()` in query builders; raw SQL in ORM `.raw()` / `.execute()` |
          | **False-positive guard** | Not a FP if the input is user-controlled (HTTP param, file, CLI arg). Env vars are trusted (see exclusion rules). |

          ## Cross-Site Scripting (XSS)

          | Aspect | Detail |
          |--------|--------|
          | **Vulnerable** | `element.innerHTML = userInput`, `dangerouslySetInnerHTML={{__html: userInput}}` |
          | **CWE** | CWE-79 (Cross-site Scripting) |
          | **Safe** | `element.textContent = userInput`, React JSX (auto-escaped), template engines with auto-escaping |
          | **Look for** | `.innerHTML`, `document.write()`, `dangerouslySetInnerHTML`, `v-html` (Vue), `bypassSecurityTrustHtml` (Angular) |
          | **False-positive guard** | React/Angular components without unsafe methods are NOT vulnerable (see exclusion rules). |

          ## Server-Side Request Forgery (SSRF)

          | Aspect | Detail |
          |--------|--------|
          | **Vulnerable** | User-controlled URL passed to server-side HTTP client: `requests.get(user_url)` |
          | **Safe** | URL allowlist validation, internal-network blocking, protocol/host restriction |
          | **Look for** | User input → `fetch`, `requests.get`, `axios.get`, `urllib`, `curl`, `http.get`; host control only (path-only is excluded) |

          ## Command Injection

          | Aspect | Detail |
          |--------|--------|
          | **Vulnerable** | User input in shell commands: `os.system(f"ping {host}")`, `subprocess.run(f"grep {pattern} file", shell=True)` |
          | **Safe** | `subprocess.run(["ping", host])` with arguments as list; `shlex.quote()` |
          | **Look for** | `shell=True`, `os.system`, `os.popen`, `exec()`, `eval()`, `$()`, backticks |
          | **False-positive guard** | Shell scripts without untrusted user input are generally not exploitable. |

          ## Authentication/Authorization Bypass

          | Aspect | Detail |
          |--------|--------|
          | **Vulnerable** | Missing auth check on protected endpoint; JWT without signature verification; hardcoded admin tokens |
          | **Safe** | Consistent auth middleware; JWT with `RS256`/`HS256` verification; role-based access control |
          | **Look for** | Routes without auth decorators; `@login_required` / `@require_auth` missing; JWT without `.verify()`; client-side auth checks only |

          ## Unsafe Deserialization

          | Aspect | Detail |
          |--------|--------|
          | **Vulnerable** | `pickle.load(user_data)`, `yaml.load(user_input)`, `JSON.parse()` on untrusted tokens, `eval(input())` |
          | **Safe** | `yaml.safe_load()`, `json.loads()` (safe for JSON), `pickle.load(weights_only=True)` (PyTorch), schema validation |
          | **Look for** | `pickle.load`, `yaml.load` (not safe_load), `torch.load(weights_only=False)`, `eval`, `marshal.load`, `node-serialize` |

          ## Path Traversal

          | Aspect | Detail |
          |--------|--------|
          | **Vulnerable** | User input in file paths: `open(f"/data/{filename}")`, `path.join(base, user_path)` |
          | **Safe** | Path normalization + prefix check: `os.path.realpath(path).startswith(BASE_DIR)`; allowlist of valid filenames |
          | **Look for** | `open()`, `read_file()`, `os.path.join` with user input; `../` traversal without normalization |

          ## Insecure Direct Object Reference (IDOR)

          | Aspect | Detail |
          |--------|--------|
          | **Vulnerable** | API endpoint uses user-supplied ID without ownership check: `GET /api/order/{order_id}` — returns any user's order |
          | **Safe** | Ownership verification: verify `order.user_id == current_user.id` before returning data |
          | **Look for** | CRUD endpoints that accept IDs without authorization; horizontal/vertical privilege checks missing |

          ## Weak Cryptography

          | Aspect | Detail |
          |--------|--------|
          | **Vulnerable** | MD5/SHA1 for passwords; ECB mode; hardcoded keys; `random` module (not `secrets`); short key lengths |
          | **Safe** | `bcrypt`/`argon2` for passwords; AES-GCM; `secrets` module; RSA 2048+; proper IV generation |
          | **Look for** | `md5`, `sha1`, `DES`, `ECB`, `PKCS1_v1_5`, `random` for crypto, hardcoded `key=`, `Crypto.Cipher` without AEAD |

          ## Secrets Exposure

          | Aspect | Detail |
          |--------|--------|
          | **Vulnerable** | Hardcoded API keys, passwords, tokens in source code; secrets in logs; secrets in client-side code |
          | **Safe** | Environment variables; secret manager (AWS Secrets Manager, HashiCorp Vault); `.env` excluded from VCS |
          | **Look for** | `API_KEY=`, `password=`, `secret=`, `token=` in code; AWS keys, GitHub tokens, Stripe keys, JWTs in source |
          | **False-positive guard** | Secrets stored on disk but otherwise secured ARE excluded. Logging high-value secrets IS a vuln. Logging URLs is safe. |

          ## Template Injection (SSTI)

          | Aspect | Detail |
          |--------|--------|
          | **Vulnerable** | User input in template rendering: `Template(user_input).render()`, `render_template_string(user_input)` |
          | **Safe** | Static templates; input passed as context variable, not template string |
          | **Look for** | `render_template_string`, `Template()()`, `eval` in template context; user input in JS template literals on server |

          ## NoSQL Injection

          | Aspect | Detail |
          |--------|--------|
          | **Vulnerable** | User input in MongoDB queries: `db.users.find({username: user_input})` where input is `{"$gt": ""}` |
          | **Safe** | Schema validation; type checking on query params; ORM sanitization |
          | **Look for** | MongoDB `$where`, `$gt`, `$regex` from user input; raw mongo queries without type coercion |
        '';
      };
    in
    {
      options.programs.pi-coding-agent.skills = {
        enable = lib.mkEnableOption "bundled curated pi skills (bug-fixing, commit, workspace, security)";
      };

      config = lib.mkIf cfg.skills.enable {
        home.file = lib.mapAttrs'
          (name: file: lib.nameValuePair "${cfg.configDir}/skills/${name}/SKILL.md" { source = file; })
          skillFiles;
      };
    };
}
