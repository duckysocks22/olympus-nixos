{ inputs, self, ... }:

{
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
        nativeBuildInputs = [ pkgs.ffmpeg pkgs.python3 ];

        buildPhase = let
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
          + lib.concatMapStrings (entry:
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
            CROP="$(python3 ${petBboxScript} 640 360 "$out" ${lib.concatStringsSep " " (map (e: "alpha-${stateName e}.raw:${stateName e}") spriteSources)})"
          ''
          + lib.concatMapStrings (entry:
            let
              src = builtins.head (builtins.split ":" entry);
              name = builtins.elemAt (builtins.split ":" entry) 2;
            in
              ''
                CROP="$(cat "$out/${name}/crop.txt")"
                ffmpeg -v error \
                  -c:v libvpx-vp9 \
                  -i "src/package/assets/webm/${src}.webm" \
                  -vf "select='not(mod(n\,${toString frameStride}))',crop=$CROP,scale=${toString (cfg.pet.sprite.size * 8)}:-1:flags=lanczos,format=rgba" \
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

      desktopPetConfig = pkgs.writeText "dsh-pet-config.json" (builtins.toJSON {
        main = {
          chatMemoryRounds = 5;
          notificationsEnabled = false;
          workStatusTexts = [
            [
              "Thinking about the next step..."
              "Let me organize my thoughts~"
              "Figuring out what comes next..."
            ]
            [
              "Working on the task..."
              "This step is in progress~"
              "Busy working, don't mind me~"
            ]
            [
              "Step done, moving on to the next"
              "One step down, let's keep going~"
            ]
            [
              "Could you confirm this part?"
              "Waiting for you to take a look~"
              "Your call — I'll wait right here~"
            ]
            [
              "All done, great job!"
              "Task complete, time to relax~"
            ]
            [
              "This step didn't work out"
              "Ran into a problem just now"
              "Hit a snag, hang tight~"
            ]
          ];
          physics = {
            gravity = 1400;
            restitution = 0.78;
            groundFriction = 2.5;
            ceilingBounce = true;
            throwPower = 1.0;
            petCollision = false;
          };
          pets = [
            {
              name = cfg.pet.name;
              id = "main";
              size = cfg.pet.desktop.size;
              balanceEnabled = false;
              whisperEnabled = true;
              workStatusEnabled = false;
              display = "desktop";
              position = {
                corner = cfg.pet.desktop.corner;
                marginX = cfg.pet.desktop.marginX;
                marginY = cfg.pet.desktop.marginY;
              };
            }
          ];
          animations = {
            idle = [ "待机呼吸休闲" ];
            turn = [ "东张西望" ];
            drag = [ "被鼠标拖拽悬空反馈" ];
            clicks = [
              "点击回应-开心跃动"
              "点击回应-害羞惊讶"
              "点击回应-傲娇生气"
              "点击回应-挠痒咯咯笑"
              "点击回应-元气挥手"
            ];
            moves = {
              default = {
                minDist = 60;
                maxDist = 240;
                margin = 20;
                leadSec = 2;
                tailSec = 2;
              };
              actions = [
                { name = "螃蟹走路"; }
                {
                  name = "原地漂浮踏步";
                  params = {
                    minDist = 40;
                    maxDist = 120;
                  };
                }
                {
                  name = "原地左转奔跑";
                  params = {
                    minDist = 120;
                    maxDist = 320;
                    leadSec = 1.75;
                    tailSec = 4.8;
                  };
                }
              ];
            };
            categories = [
              {
                id = "Fidgets";
                weight = 20;
                actions = [
                  "悠闲哼歌"
                  "超大伸懒腰"
                  "原地敲击桌面互动"
                  "原地重力下蹲压缩"
                  "哈欠连天"
                  "原地小憩沉眠"
                  "女仆屈膝礼仪"
                  "被吓一跳"
                  "小幅度原地360度旋转展示"
                  "偷吃零食被抓住"
                  "用鲸鱼尾巴拍打地面"
                  "打瞌睡被惊醒"
                  "照镜子"
                  "整体换装试色"
                  "轻快记录"
                  "写代码"
                  "摇扇纳凉"
                  "晨间刷牙"
                ];
              }
              {
                id = "Play";
                weight = 20;
                actions = [
                  "原地专心玩魔方"
                  "原地蹲下玩玩具汽车"
                  "鲸鱼吐泡泡特效"
                  "原地跳跃抓碎头顶物品"
                  "玩游戏气急败坏"
                  "玩水枪"
                  "小提琴演奏"
                  "蓝鲸现世"
                  "优雅女仆舞"
                  "轻快摇摆舞"
                  "可爱宅舞"
                  "吹气球"
                  "动物环绕"
                  "放风筝"
                  "拆礼物"
                  "变鸽子"
                  "扑克魔术"
                  "抽陀螺"
                  "吹笛子"
                  "蝴蝶蜜蜂环绕头顶开花"
                  "撸猫"
                  "凭空生花"
                  "骑木马"
                  "三球抛接"
                  "踢毽子"
                  "下五子棋"
                  "荡秋千"
                ];
              }
              {
                id = "Snacks";
                weight = 16;
                actions = [
                  "吃白饭"
                  "大口吃零食"
                  "吃Token"
                  "吃早餐"
                  "吃午餐"
                  "吃晚餐"
                  "吃冰淇淋融化"
                  "吃大闸蟹"
                  "吃糖葫芦"
                  "吃长寿面"
                  "吃西瓜"
                  "涮火锅"
                ];
              }
              {
                id = "Seasonal";
                weight = 14;
                actions = [
                  "被落叶淹没"
                  "中秋赏月吃月饼"
                  "堆雪人"
                  "放烟花"
                  "吃粽子"
                  "吃年糕"
                  "吃青团"
                  "吃腊八粥"
                  "吃重阳糕"
                  "收红包"
                  "写福字"
                  "穿针乞巧"
                  "舞狮头"
                  "讨糖南瓜灯"
                  "插茱萸赏菊"
                  "放河灯"
                  "萌化小幽灵"
                  "装点圣诞树"
                  "放孔明灯"
                  "吃汤圆"
                  "吃饺子"
                ];
              }
              {
                id = "Words";
                weight = 10;
                noMirror = true;
                actions = [
                  "是啊，吃什么"
                  "深度思考碎碎念"
                ];
              }
            ];
            events = {
              balance = [
                "余额-钱袋满溢"
                "余额-金袋叮当"
                "余额-钱袋如常"
                "余额-数金皱眉"
                "余额-袋空如洗"
                "余额-分文不剩"
              ];
              whisper = [
                "碎碎念-擦桌碎碎念"
                "碎碎念-发呆碎碎念"
                "碎碎念-对屏碎碎念"
              ];
              workStatus = [
                "工作状态-思考冒泡"
                "工作状态-忙碌点按"
                "工作状态-清点归档"
                "工作状态-原地踱步张望"
                "工作状态-雀跃庆祝"
                "工作状态-垂头叹气冒汗"
              ];
            };
          };
          eventsRefreshSec = {
            balance = 1800;
            whisper = 300;
          };
          animationWeights = {
            idle = 10;
            turn = 5;
            move = 5;
          };
        };
      });

      desktopPetList = pkgs.writeText "pi-pet-pets.json" (
        builtins.toJSON [
          {
            id = "main";
            size = cfg.pet.desktop.size;
          }
        ]
      );

      desktopWhispers = pkgs.writeText "pi-pet-whispers.json" (builtins.toJSON cfg.pet.whispers.messages);

      piPetDesktop =
        let
          appConfig = desktopPetConfig;
          appPets = desktopPetList;
          appWhispers = desktopWhispers;
        in
        pkgs.stdenvNoCC.mkDerivation {
          pname = "pi-pet-desktop";
          version = "0.2.8";

          src = ../../assets/pi-pet-desktop;
          dontBuild = true;

          nativeBuildInputs = [ pkgs.makeWrapper ];

          installPhase = ''
            runHook preInstall

            mkdir -p $out/lib/dsh-pet $out/lib/pi-pet $out/bin
            tar -xzf ${dshPetTarball}
            cp -r package/assets package/runtime $out/lib/dsh-pet/
            cp host.mjs $out/lib/pi-pet/host.mjs
            cp ${appConfig} $out/lib/pi-pet/config.json
            cp ${appPets} $out/lib/pi-pet/pets.json
            cp ${appWhispers} $out/lib/pi-pet/whispers.json

            sed -i \
              -e 's/"动作"/"Actions"/g' \
              -e 's/"待机"/"Idle"/g' \
              -e 's/"转向"/"Turn"/g' \
              -e 's/"拖拽"/"Drag"/g' \
              -e 's/"点击回应"/"Click"/g' \
              -e 's/"移动"/"Move"/g' \
              $out/lib/dsh-pet/runtime/electron-helper/shared-core.js

            cat > $out/bin/pi-pet <<'WRAP'
            #!/usr/bin/env bash
            PORT=$(( 30000 + $$ % 20000 ))
            export DSH_PET_CONFIG_URL="http://127.0.0.1:$PORT/dsh-pet-7340/config"
            export DSH_PET_PETS="$(cat @out@/lib/pi-pet/pets.json)"
            @node@/bin/node @out@/lib/pi-pet/host.mjs \
              --port "$PORT" \
              --root @out@/lib/dsh-pet \
              --config @out@/lib/pi-pet/config.json \
              --whispers @out@/lib/pi-pet/whispers.json &
            SRV=$!
            trap 'kill $SRV 2>/dev/null' EXIT INT TERM
            @electron@/bin/electron @out@/lib/dsh-pet/runtime/electron-helper/main.js --no-sandbox "$@"
            RC=$?
            kill $SRV 2>/dev/null
            exit $RC
            WRAP
            substituteInPlace $out/bin/pi-pet \
              --replace @out@ "$out" \
              --replace @node@ "${pkgs.nodejs}" \
              --replace @electron@ "${pkgs.electron}"
            chmod +x $out/bin/pi-pet
            wrapProgram $out/bin/pi-pet \
              --prefix PATH : ${lib.makeBinPath [ pkgs.nodejs pkgs.electron ]}

            runHook postInstall
          '';

          meta = {
            description = "Standalone desktop pet (dsh-pet assets, English whispers), launched via pi-pet";
            license = lib.licenses.mit;
            mainProgram = "pi-pet";
            platforms = [ "x86_64-linux" ];
          };
        };
    in
    {
      options.programs.pi-coding-agent.pet = {
        enable = lib.mkEnableOption "pi-coding-agent desktop pet companion (ported from dsh-pet)";

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
            description = "Periodic whispers: TUI bubble/notifications and desktop speech bubbles.";
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
            description = "Pool of whisper lines (TUI bubble and desktop speech bubbles).";
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

        desktop = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Also install the standalone desktop overlay pet (separate always-on-top window).";
          };
          size = lib.mkOption {
            type = lib.types.int;
            default = 462;
            description = "Pet width in pixels (height is width x 9/16).";
          };
          corner = lib.mkOption {
            type = lib.types.enum [
              "top-left"
              "top-right"
              "bottom-left"
              "bottom-right"
            ];
            default = "top-right";
            description = "Screen corner the pet lives in.";
          };
          marginX = lib.mkOption {
            type = lib.types.int;
            default = 24;
            description = "Horizontal offset from the corner, in pixels.";
          };
          marginY = lib.mkOption {
            type = lib.types.int;
            default = 100;
            description = "Vertical offset from the corner, in pixels.";
          };
          autostart = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Start the overlay pet automatically with the graphical session (systemd user service pi-pet).";
          };
        };
      };

      config = lib.mkIf cfg.pet.enable {
        home.file = {
          "${cfg.configDir}/extensions/pi-pet/index.ts".source = extensionFile;
        };

        home.packages = lib.mkIf cfg.pet.desktop.enable [ piPetDesktop ];

        systemd.user.services.pi-pet = lib.mkIf (cfg.pet.desktop.enable && cfg.pet.desktop.autostart) {
          Unit = {
            Description = "Pi desktop pet (dsh-pet standalone)";
            PartOf = [ "graphical-session.target" ];
          };
          Service = {
            ExecStart = "${piPetDesktop}/bin/pi-pet";
            Restart = "on-failure";
            RestartSec = 5;
          };
          Install = {
            WantedBy = [ "graphical-session.target" ];
          };
        };
      };
    };
}
