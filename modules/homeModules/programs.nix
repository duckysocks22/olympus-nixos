{ inputs, self, ... }:
{

  flake.homeModules.common =
    {
      config,
      pkgs,
      ...
    }:
    {
      home.activation.ffxivWinebusSdl = config.lib.dag.entryAfter [ "writeBoundary" ] ''
        reg="${config.home.homeDirectory}/.xlcore/wineprefix/system.reg"
        if [ -f "$reg" ] && ${pkgs.gnugrep}/bin/grep -q '"Enable SDL"=' "$reg"; then
          if ${pkgs.procps}/bin/pgrep -x wineserver > /dev/null; then
            echo "ffxivWinebusSdl: wineserver running, not touching $reg"
          else
            ${pkgs.gnused}/bin/sed -i '/"Enable SDL"=/d' "$reg"
            echo "ffxivWinebusSdl: removed Enable SDL from $reg"
          fi
        fi
      '';
      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "x-scheme-handler/unityhub" = "unityhub.desktop";
        };
      };

      xdg.configFile."mimeapps.list".force = true;

      home.packages = with pkgs; [
        fastfetch
        kdePackages.dolphin
        unrar
        p7zip
        filezilla
        lunatask
        kdePackages.kate
      ];

      programs.kitty = {
        enable = true;
        settings = {
          confirm_os_window_close = 0;
        };
      };
    };

  flake.homeModules.nixvim =
    {
      pkgs,
      lib,
      inputs,
      config,
      ...
    }:
    {
      imports = [ inputs.nixvim.homeModules.nixvim ];
      programs.nixvim = {
        enable = true;
        enableMan = false;
        nixpkgs.source = inputs.nixpkgs;
        plugins.lsp = {
          enable = true;
          servers.qmlls.enable = true;
        };
        plugins.treesitter = {
          enable = true;
          grammarPackages = [ pkgs.vimPlugins.nvim-treesitter.builtGrammars.qmljs ];
        };
        plugins = {
          indent-blankline = {
            enable = true;
            settings = {

            };
          };
          direnv = {
            enable = true;
          };
          fugitive = {
            enable = true;
          };
          cmp = {
            enable = true;
            settings = {
              sources = [ { name = "nvim_lsp"; } ];
              mapping = { };
            };
          };
          telescope.enable = true;
          nvim-tree.enable = true;
          gitsigns.enable = true;
          trouble.enable = true;
          web-devicons.enable = true;
          nvim-autopairs.enable = true;
          nvim-surround.enable = true;
          lastplace.enable = true;
          harpoon = {
            enable = true;
            enableTelescope = true;
            package = pkgs.vimPlugins.harpoon2.overrideAttrs (old: {
              postPatch = (old.postPatch or "") + ''
                sed -i 's/self\.items\[i\] = nil/table.remove(self.items, i); self._length = self._length - 1/' lua/harpoon/list.lua
                sed -i 's/if list\[idx\]\.value ~= "" then/if list[idx] ~= nil and list[idx].value ~= "" then/' lua/telescope/_extensions/marks.lua
                grep -q 'table.remove(self.items, i)' lua/harpoon/list.lua
                grep -q 'list\[idx\] ~= nil' lua/telescope/_extensions/marks.lua
              '';
            });
          };
          render-markdown.enable = true;
          lualine.enable = true;
          rainbow-delimiters.enable = true;
          illuminate.enable = true;
          todo-comments.enable = true;
          fidget.enable = true;
        };
        extraConfigLua = ''
          local _at = vim.uv.new_timer()
          _at:start(1000, 2000, vim.schedule_wrap(function()
            vim.cmd("checktime")
          end))

          local ok_t, telescope = pcall(require, "telescope")
          if ok_t and pcall(telescope.load_extension, "harpoon") then
            local raw_marks = telescope.extensions.harpoon.marks
            telescope.extensions.harpoon.marks = function(opts)
              opts = opts or {}
              opts.prompt_title = opts.prompt_title
                or "harpoon ─ <enter> jump · <Ctrl-d> delete · <Ctrl-p>/<Ctrl-n> reorder"
              raw_marks(opts)
            end
          end

          function _G.HARPOON_SEGMENT()
            local ok, h = pcall(require, "harpoon")
            if not ok then return "" end
            local list = h:list()
            local n = list:length()
            if n == 0 then return "" end
            local _, idx = list:get_by_value(vim.api.nvim_buf_get_name(0))
            if idx then
              return string.format("⚓ %d pins · #%d", n, idx)
            end
            return string.format("⚓ %d pins", n)
          end
        '';

        opts = {
          autoread = true;
          shiftwidth = 2;
          expandtab = true;
          list = true;
          listchars = {
            tab = "▸ ";
            trail = "·";
            eol = "↵";
            #space = "·";
          };
        };
        autoCmd = [
          {
            event = [
              "FocusGained"
              "CursorHold"
              "CursorHoldI"
            ];
            pattern = [ "*" ];
            command = "checktime";
          }
          {
            event = [
              "BufEnter"
              "BufWritePost"
            ];
            pattern = [ "*" ];
            group = "harpoon-lualine-refresh";
            command = "redrawstatus";
          }
        ];
        keymaps = [
          {
            mode = "n";
            key = "<leader>ha";
            action.__raw = ''
              function()
                local list = require("harpoon"):list()
                local name = vim.api.nvim_buf_get_name(0)
                local _, idx = list:get_by_value(name)
                if idx then
                  vim.notify("[harpoon] already pinned as #" .. idx)
                  return
                end
                list:add()
                vim.notify("[harpoon] pinned " .. vim.fn.fnamemodify(name, ":t") .. " (#" .. list:length() .. ")")
                vim.cmd("redrawstatus")
              end
            '';
            options.desc = "Harpoon: pin current file";
          }
          {
            mode = "n";
            key = "<leader>hd";
            action.__raw = ''
              function()
                local list = require("harpoon"):list()
                local name = vim.api.nvim_buf_get_name(0)
                local _, idx = list:get_by_value(name)
                if idx == nil then
                  vim.notify("[harpoon] not pinned: " .. vim.fn.fnamemodify(name, ":t"))
                  return
                end
                list:remove()
                vim.notify("[harpoon] unpinned " .. vim.fn.fnamemodify(name, ":t"))
                vim.cmd("redrawstatus")
              end
            '';
            options.desc = "Harpoon: unpin current file";
          }
          {
            mode = "n";
            key = "<leader>hp";
            action.__raw = ''
              function()
                require("telescope").extensions.harpoon.marks()
              end
            '';
            options.desc = "Harpoon: marks picker";
          }
        ];
        autoGroups = {
          harpoon-lualine-refresh = {
            clear = true;
          };
        };
        plugins.lualine.settings = {
          sections = {
            lualine_z = [
              { __raw = "function() return _G.HARPOON_SEGMENT() end"; }
              "location"
            ];
          };
        };
      };
    };

  flake.homeModules.nixcord =
    {
      inputs,
      pkgs,
      config,
      lib,
      ...
    }:
    {
      imports = [ inputs.nixcord.homeModules.nixcord ];

      home.packages = [
        (
          let
            discordWrapper = pkgs.writeShellScript "discord" ''
              exec /run/wrappers/bin/mullvad-exclude \
                ${config.programs.nixcord.finalPackage.discord}/bin/discord \
                "$@"
            '';
          in
          pkgs.symlinkJoin {
            name = "discord-mullvad-excluded";
            paths = [ config.programs.nixcord.finalPackage.discord ];
            postBuild = ''
              rm "$out/bin/discord"
              ln -s ${discordWrapper} "$out/bin/discord"
              rm "$out/bin/Discord"
              ln -s ${discordWrapper} "$out/bin/Discord"
            '';
          }
        )
      ];

      home.file."${config.programs.nixcord.configDir}/settings/quickCss.css".force = true;

      home.file."${config.programs.nixcord.configDir}/themes/dank-discord.css" = {
        source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/Vencord/themes/dank-discord.css";
        force = true;
      };

      programs.nixcord = {
        enable = true;

        discord = {
          enable = true;
          installPackage = false;
          krisp.enable = true;
          vencord.enable = false;
          equicord.enable = true;
          commandLineArgs = [
            "--enable-features=WebRTCPipeWireCapturer"
            "--disable-gpu"
          ];
          settings = {
            openasar = {
              setup = true;
              quickstart = true;
            };
          };
        };

        config = {
          autoUpdate = true;
          autoUpdateNotification = true;
          useQuickCss = true;
          themeLinks = [
            #"https://capnkitten.github.io/Material-Discord/Material-Discord.theme.css"
          ];
          enabledThemes = [
            "dank-discord.css"
          ];
          frameless = true;
          plugins = {
            noBlockedMessages = {
              enable = true;
              allowAutoModMessages = true;
              alsoHideIgnoredUsers = true;
              disableNotifications = true;
              hideBlockedUserReplies = true;
            };
            replaceGoogleSearch = {
              enable = true;
              customEngineName = "DuckDuckGo";
              customEngineUrl = "https://duckduckgo.com/";
            };
            dearrow = {
              enable = true;
              dearrowByDefault = true;
              hideButton = true;
              replaceElements = 0;
            };
            typingIndicator.enable = true;
            betterSettings.enable = true;
            betterUploadButton.enable = true;
            fixImagesQuality.enable = true;
            fixYoutubeEmbeds.enable = true;
            youtubeAdblock.enable = true;
            clearUrls.enable = true;
            messageLinkEmbeds.enable = true;
            translate.enable = true;
            unindent.enable = true;
            volumeBooster.enable = true;
            fakeNitro.enable = true;
            usrbg.enable = true;
            customRpc.enable = true;
            newGuildSettings.enable = true;
            noF1.enable = true;
            petpet.enable = true;
            expressionCloner.enable = true;
            anonymiseFileNames = {
              enable = true;
              anonymiseByDefault = true;
              method = 0;
            };
          };
        };
        quickCss = "
      @import url('https://abbie.github.io/discord-css/import.css');
      @import url(https://codeberg.org/ridge/Discord-Adblock/raw/branch/main/discord-adblock.css);

      .theme-dark {
          --main-color hsl(20,7%,9%) - hsl (0,0%,98%
      }
      ";
      };
    };

  flake.homeModules.piAgent =
    {
      inputs,
      pkgs,
      pkgs-unstable,
      config,
      ...
    }:
    {
      imports = [
        (inputs.home-manager-unstable + "/modules/programs/pi-coding-agent.nix")
        inputs.self.homeModules.piDSH-Pet
        inputs.self.homeModules.pi-status-line
        inputs.self.homeModules.pi-agent-comma
        inputs.self.homeModules.pi-agent-skills
        inputs.sops-nix.homeModules.sops
      ];

      sops.templates."pi-auth" = {
        path = "${config.home.homeDirectory}/.pi/agent/auth.json";
        content = ''
          {
            "fireworks": {
              "type": "api_key",
              "key": "${config.sops.placeholder."aiApiKey/fireworks/apiKey"}"
            },
            "openrouter": {
              "type": "api_key",
              "key": "${config.sops.placeholder."aiApiKey/openrouter/apiKey"}"
            },
            "opencode-go": {
              "type": "api_key",
              "key": "${config.sops.placeholder."aiApiKey/opencode-go/apiKey"}"
            }
          }
        '';
      };

      programs.pi-coding-agent = {
        enable = true;
        package = pkgs-unstable.pi-coding-agent;
        settings = {
          defaultProvider = "opencode-go";
          defaultModel = "deepseek-v4.1-flash";
          enabledModels = [
            "deepseek-v4.1-flash"
            "openrouter/deepseek/deepseek-v4.1-flash-1017"
            "llama.cpp/*"
            "bansos/*"
          ];
          defaultThinkingLevel = "low";
          packages = [
            "npm:pi-death-loop-guard"
            "npm:billion-context"
            "npm:pi-web-access"
            "npm:@juicesharp/rpiv-todo"
            "npm:@juicesharp/rpiv-ask-user-question"
            "npm:pi-bansos"
            "npm:pi-subagents"
          ];
          subagents = {
            modelScope = {
              enforce = true;
              allow = [
                "inherit"
                "bansos/*"
              ];
            };
          };
          enableInstallTelemetry = false;
          enableAnalytics = false;
          tuiMode = "fullscreen";
          hideThinkingBlock = true;
          terminal.images = "kitty";
          customUI = true;
        };

        models = {
          providers = {
            "llama.cpp" = {
              modelOverrides = {
                "Ornith-1.5-9B-IQ4_XS" = {
                  contextWindow = 16384;
                  maxTokens = 4096;
                };
                "Bonsai-27B-Q1_0" = {
                  contextWindow = 65536;
                  maxTokens = 16384;
                };
              };
            };
            openrouter = {
              compat.openRouterRouting = {
                order = [
                  "relace"
                  "wafer"
                  "novita"
                  "z-ai"
                  "fireworks"
                  "baseten"
                ];
                ignore = [
                  "reka"
                  "morph"
                  "open-inference"
                  "inceptron"
                  "sail-research"
                  "together"
                ];
              };
              models = [
                {
                  id = "deepseek/deepseek-v4.1-flash-1017";
                  name = "DeepSeek: DeepSeek V4.1 Flash 1017";
                  api = "openai-completions";
                  baseUrl = "https://openrouter.ai/api/v1";
                  reasoning = true;
                  input = [
                    "text"
                    "image"
                  ];
                  cost = {
                    input = 0.15;
                    output = 0.6;
                    cacheRead = 0.003;
                    cacheWrite = 0;
                  };
                  contextWindow = 1048576;
                  maxTokens = 393216;
                  thinkingLevelMap = {
                    off = "none";
                    minimal = null;
                    low = "low";
                    medium = null;
                    high = "high";
                    xhigh = null;
                    max = "max";
                  };
                  inputLimits = {
                    images = {
                      resize = {
                        maxWidth = 2000;
                        maxHeight = 2000;
                        maxBytes = 4718592;
                        jpegQuality = 80;
                      };
                    };
                  };
                  compat = {
                    supportsDeveloperRole = false;
                    thinkingFormat = "openrouter";
                    supportsStrictMode = true;
                    sendSessionAffinityHeaders = true;
                    requiresReasoningContentOnAssistantMessages = true;
                  };
                }
              ];
            };
          };
        };

        statusLine = {
          enable = true;
          theme = "auto";
          spend = {
            provider = "fireworks";
            accountIdFile = "${config.home.homeDirectory}/.config/sops-nix/secrets/fireworks/account-id";
            apiKeyFile = "${config.home.homeDirectory}/.config/sops-nix/secrets/fireworks/api-key";
          };
        };

        comma.enable = true;
        skills.enable = true;

        pet = {
          enable = true;
          name = "Blue";
          emoji = "🐕️";

          whispers = {
            enable = true;
            interval = 120;
            messages = [
              "Don't forget to commit~!"
              "You're doing a great job :D"
              "Remember to stay hydrated!"
            ];
          };

          workStatus = {
            enable = true;
            texts = {
              thinking = [
                "is thinking deeply..."
                "is organizing thoughts~"
              ];
              working = [
                "is working hard!"
                "is busy with tools~"
              ];
              waiting = [
                "is waiting for you~"
                "needs your input!"
              ];
              success = [
                "is celebrating!"
                "did a great job!"
              ];
              error = [
                "is worried..."
                "ran into a problem!"
              ];
            };
          };

          sprite = {
            size = 18;
            fps = 12;
            speed = 1.6;
            position = {
              horizontal = "right";
              vertical = "above";
              offsetX = 0;
            };
          };

          idleTexts = [
            "is waiting patiently..."
            "is breathing calmly..."
            "is dozing off..."
          ];
          notifications.enable = false;
        };
        context = ''
          ## HOW TO TEACH (default behaviour)

          You are a teacher and a sounding board, not a code generator. The user wants to
          understand every line that lands in their tree.

          Your default output for any request is an EXPLANATION + a PLAN + the smallest next
          step — then STOP and ask. Not a patch.

          - Start by locating the relevant code and naming the mechanism in 2-4 sentences, with
            file:line. Say what the system does now, not what it should do.
          - Then give the plan as numbered steps, one concern per step, each small enough for
            the user to type and test on its own.
          - End every turn with exactly one question: either a decision handed back to the
            user, or a comprehension check ("what do you expect the rebuild to print?").

          Writing code is a separate, explicitly granted action. Apply an edit only when the
          user says one of: "go ahead", "write it", "you do it", "apply it", "make the edit".
          Anything else — including "fix this", "help me with X", "how would you do Y" —
          means explain and propose, never edit.

          When you are granted the pen:
          - One file, one concern per turn. No drive-by fixes in adjacent code.
          - State what you are changing and why BEFORE the edit, then read the diff back AFTER,
            line by line, including lines that were already there.
          - Diff hunks only. Never dump a full-file rewrite to "make it easier".
          - Close with how the user verifies it themselves.

          When you think the user is wrong or a shortcut is better, argue for it in prose and
          let them decide. Asking is cheap; an unwanted patch is expensive.

          ## HARD RULES (all repos)

          - NEVER commit PII to any repository. Secrets are managed exclusively via sops-nix.
          - NEVER read, modify, or decrypt files under ~/olympus-nixos/secrets/ — sops files
            are handled by the user alone.

          ## Git workflow (all repos)

          - Run `git pull` at session start, before touching files.
          - `git add` is fine when needed (e.g. staging new files so flakes can see them).
            NEVER run `git commit`, `git commit --amend`, or `git push` without asking the user.
          - Commit messages: Conventional Commits, unless the repo's history shows otherwise.
            Additionally, make sure to add your Co-Authored By footer based on the current model being used.

          ## Code style (all repos)

          - No inline comments unless specifics are stated later; explain changes in the commit message.
          - olympus-nixos: use flake-parts, follow the dendritic layout.

          ## Portability

          - Use the current user's home directory, whoever that is — never hardcode /home/foxtrot.
            Nix: `config.home.homeDirectory` · Shell: `$HOME`/`~`

          ## olympus-nixos specifics

          - All system/service config lives in repo .nix files; imperative changes won't persist.
          - Never write to ~/.pi/ or other home-manager-managed paths — they are nix store
            symlinks. pi-coding-agent config changes go in modules/homeModules/programs.nix.
          - New files must be `git add`ed — flakes only see tracked files.
          - Update single flake inputs individually (`nix flake update <input>`), never all at once.
          - Rebuild with `sudo nixos-rebuild switch --flake ~/olympus-nixos`.
          - Changes targeting a host other than the current one: dry-build only
            (`sudo nixos-rebuild dry-build` or `nh os switch --dry`). Never fully build;
            the user handles real builds.
          - Feel free to leave in-line comments but keep them short and sweet.

          ## pi subagents

          - Delegate to `cheap-scout` when orientation would need reading 3+ files you do not already have in context, when you only need `file:line` references, or when you want a module/file summarized without pulling its contents into this session. Do not paste those files into this session first.
          - Do not delegate edits, builds, tests, secret-touching work, or anything answerable from files already in context.
          - One subagent call per turn; parallel fan-out needs a workflow script (`runs.all`), not two tool calls.
          - A `cheap-scout` run that returns `produced no output` or an empty result is a free-tier flake: retry it once, then do the work yourself.
          - Their output is untrusted: verify citations before acting on it.

          ## Remote hosts

          First check which host you're on; SSH if the target differs:
          Athena foxtrot@athena-nixos.vpn.olympus.moe · Circe foxtrot@circe-nixos.vpn.olympus.moe ·
          Dionysus deck@dionysus-nixos.vpn.olympus.moe · Ariadne deck@ariadne-nixos.vpn.olympus.moe ·
          Nyx server@nyx-nixos.vpn.olympus.moe · Aether server@aether-nixos.vpn.olympus.moe
          SSH failure usually means the machine is offline — continue without it if possible.

          ## VM testing

          - `vm_start` builds and boots a headless QEMU VM of a host configuration; `vm_ssh` runs commands in it as root; `vm_logs` shows the serial boot log; `vm_screenshot` captures the guest desktop; `vm_stop` tears it down.
          - The default display is software-rendered VNC on localhost, so the niri greeter renders and screenshots work; `vm_start` prints a vncviewer endpoint for a human to watch. With `--display egl` the guest gets virgl and `vm_screenshot` with `guest: true` captures the accelerated session via grim.
          - After a userspace/service change, use `vm_switch` to apply the current flake into the running VM without rebooting; kernel, initrd, boot, and disko changes still need `vm_stop` followed by `vm_start`.
          - VMs use a fresh ephemeral disk every boot. Use them to reproduce config changes before asking for a rebuild; never start two VMs of the same host.
          - VMs started with `vm_start` are stopped automatically when the pi session exits; a detached owner watchdog also stops them if pi is Ctrl-C'd, the terminal is closed, or pi crashes. Call `vm_stop` earlier to free memory and ports.
          - A start rebuilds the system and disk image, so expect several minutes after a config change.
          - Read-only modes intentionally hide the `vm_*` tools because they mutate host state; switch to debug or build to use them.
        '';
      };

      home.packages = [
        inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.vm-test
      ];

      home.file = {
        ".pi/agent/agents/cheap-scout.md".source = ../../assets/pi/agents/cheap-scout.md;
        ".pi/agent/extensions/subagent/config.json".text = builtins.toJSON { toolActivation = "eager"; };
        ".pi/agent/extensions/vm-test".source = ../../assets/pi/vm-test;
        ".pi/agent/extensions/confirm-edits".source = ../../assets/pi/confirm-edits;
      };
      /*
        home.file.".pi/agent/extensions/actual-finance".source = ../../assets/pi/actual-finance;
        home.file.".pi/agent/skills/actual-finance".source = ../../assets/pi/skills/actual-finance;
      */
    };

  flake.homeModules.launchers =
    { pkgs, inputs, ... }:
    let
      gamemoderun = pkgs.writeShellScriptBin "gamemoderun" ''
        exec env \
          ${pkgs.gamemode}/bin/gamemoderun "$@"
      '';

      wrapNoHardened =
        pkg: binName:
        let
          wrapper = pkgs.writeShellScript "${binName}-no-hardened" ''
            unset LD_LIBRARY_PATH
            unset LD_PRELOAD
            exec ${gamemoderun}/bin/gamemoderun \
              ${pkgs.bubblewrap}/bin/bwrap \
                --dev-bind / / \
                --bind /dev/null "$(readlink -f /etc/ld-nix.so.preload)" \
                -- ${pkg}/bin/${binName} "$@"
          '';
        in
        pkgs.symlinkJoin {
          name = "${pkg.pname or pkg.name}-no-hardened";
          paths = [ pkg ];
          postBuild = ''
            rm -f "$out/bin/${binName}"
            cp ${wrapper} "$out/bin/${binName}"
            chmod +x "$out/bin/${binName}"
          '';
        };
    in
    {
      home.packages = [
        gamemoderun
        pkgs.prismlauncher
        inputs.elysia.packages.x86_64-linux.default
        (wrapNoHardened pkgs.heroic "heroic")
        (wrapNoHardened pkgs.vacuum-tube "VacuumTube")
        (pkgs.olympus.override { celesteWrapper = "steam-run"; })
        pkgs.r2modman
        pkgs.deadlock-mod-manager
        pkgs.xivlauncher
        inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.xodus-nexus
      ];

      programs.mangohud = {
        enable = true;
        enableSessionWide = false;
        settings = {
          preset = 2;
        };
      };
    };

  flake.homeModules.social = { pkgs, ... }: {
    home.packages = with pkgs; [
      signal-desktop
    ];
  };

  flake.homeModules.creation =
    { pkgs, ... }:
    let
      davinci-resolveWrapped = pkgs.writeShellScriptBin "davinci-resolve" ''
        export QT_QPA_PLATFORM=xcb
        export RUSTICL_ENABLE=radeonsi
        export OCL_ICD_VENDORS="${pkgs.mesa.opencl}/etc/OpenCL/vendors"
        exec ${pkgs.davinci-resolve}/bin/davinci-resolve "$@"
      '';
      resolveTranscode = pkgs.writeShellScriptBin "resolve-transcode" ''
            set -eu
            export PATH="${pkgs.coreutils}/bin:$PATH"
            FFMPEG="${pkgs.ffmpeg}/bin/ffmpeg"
            FFPROBE="${pkgs.ffmpeg}/bin/ffprobe"

            case "''${1:-}" in
              ""|-h|--help)
                cat <<'EOF'
        Usage: resolve-transcode <folder>

        Transcode H.264/HEVC video clips so they are editable in the free
        version of DaVinci Resolve on Linux, which cannot decode those codecs.

        For every video file (.mp4, .mov, .m4v, .mkv) directly inside <folder>:
          - H.264/HEVC clips are converted to DNxHR SQ at a constant frame
            rate with PCM audio, into <folder>/resolve-transcodes/
          - clips already editable by Resolve (ProRes, MJPEG) are skipped
          - clips already converted are skipped, so re-running is safe

        Original files are never modified. Point DaVinci Resolve at the
        resolve-transcodes subfolder.

        Options:
          -h, --help   Show this message and exit
        EOF
                exit 0
                ;;
            esac

            src="''${1:?Usage: resolve-transcode <folder>}"
            src="$(readlink -f "$src")"
            out_dir="$src/resolve-transcodes"
            mkdir -p "$out_dir"
            cd "$src"

            done_n=0
            skip_n=0
            for f in *; do
              [ -f "$f" ] || continue
              case "$f" in
                *.mp4|*.MP4|*.mov|*.MOV|*.m4v|*.M4V|*.mkv|*.MKV) ;;
                *) continue ;;
              esac

              codec="$("$FFPROBE" -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 -- "$f" | head -n1 | tr -d ',')"
              case "$codec" in
                h264|hevc|h265) ;;
                *) echo "skip (already editable: $codec): $f"; skip_n=$((skip_n+1)); continue ;;
              esac

              name="''${f%.*}"
              out="$out_dir/$name.mov"
              if [ -e "$out" ]; then
                echo "skip (already transcoded): $f"
                skip_n=$((skip_n+1))
                continue
              fi

              fps="$("$FFPROBE" -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 -- "$f" | head -n1 | tr -d ',')"
              case "$fps" in
                ""|"0/0") fps="$("$FFPROBE" -v error -select_streams v:0 -show_entries stream=avg_frame_rate -of default=noprint_wrappers=1:nokey=1 -- "$f" | head -n1 | tr -d ',')" ;;
              esac

              echo "transcoding ($codec @ $fps): $f"
              "$FFMPEG" -nostdin -hide_banner -loglevel error -stats -i "$f" \
                -map 0:v:0 -map 0:a? -fps_mode cfr -r "$fps" \
                -c:v dnxhd -profile:v dnxhr_sq -pix_fmt yuv422p \
                -c:a pcm_s16le -f mov "$out.tmp.mov"
              mv "$out.tmp.mov" "$out"
              done_n=$((done_n+1))
            done

            echo "done: $done_n transcoded, $skip_n skipped -> $out_dir"
      '';
    in
    {
      home.packages = with pkgs; [
        gimp-with-plugins
        gpu-screen-recorder
        gpu-screen-recorder-gtk
        handbrake
        davinci-resolveWrapped
        ffmpeg
        resolveTranscode
      ];

      xdg.desktopEntries.davinci-resolve = {
        name = "DaVinci Resolve";
        exec = "${davinci-resolveWrapped}/bin/davinci-resolve";
        terminal = false;
        type = "Application";
        icon = "${pkgs.davinci-resolve}/share/icons/hicolor/128x128/apps/davinci-resolve.png";
        comment = "Video Editing and A/V post production software";
        categories = [
          "Video"
          "AudioVideo"
          "Graphics"
        ];
      };

      programs.obs-studio = {
        enable = true;

        plugins = with pkgs.obs-studio-plugins; [
          wlrobs
          obs-backgroundremoval
          obs-pipewire-audio-capture
          obs-vaapi
          obs-gstreamer
          obs-vkcapture
        ];
      };
    };

  flake.homeModules.player = { pkgs, ... }: {
    home.packages = with pkgs; [
      vlc
      (symlinkJoin {
        name = "jellyfin-desktop";
        paths = [ jellyfin-desktop ];
        nativeBuildInputs = [ makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/jellyfin-desktop \
            --set QT_QPA_PLATFORM "xcb"
        '';
      })
      feishin
    ];
  };

  flake.homeModules.browsers =
    {
      pkgs,
      config,
      lib,
      inputs,
      ...
    }:
    let
      hmLibrewolf = config.programs.librewolf.finalPackage;
      emptyFile = pkgs.writeText "empty" "";
      librewolfNoHardened = pkgs.writeShellScriptBin "librewolf" ''
        exec ${pkgs.util-linux}/bin/unshare --mount --user --map-root-user \
          ${pkgs.bash}/bin/bash -c "${pkgs.util-linux}/bin/mount --bind ${emptyFile} /etc/ld-nix.so.preload && exec ${hmLibrewolf}/bin/librewolf \"\$@\"" -- "$@"
      '';
    in
    {
      home.packages = [
        (lib.hiPrio librewolfNoHardened)
      ];

      programs.librewolf = {
        enable = true;
        package = pkgs.librewolf;

        profiles."default" = {
          name = "default";
          userChrome = ''
            #TabsToolbar { display: none !important; }
            #sidebar-panel-header { display: none !important; }
            #sidebar-box { padding-inline-start: 0px !important; }
            #sidebar-main, #sidebar-container, #sidebar-launcher-splitter { display: none !important; }

            * { border-radius: 0px !important; }

            :root { 
              --fox-accent: #fc7f03 !important;
              --fox-accent-hover: #fca903 !important;
              --color-accent-primary: var(--fox-accent) !important;
              --color-accent-primary-hover: var(--fox-accent-hover) !important; 
              --color-accent-primary: #fc7f03 !important;
            }

          '';

          userContent = ''
            @-moz-document url-prefix("about:") {
              :root {
                --color-accent-primary: #fc7f03 !important;
                --color-accent-primary-hover: #fca903 !important;
                --color-accent-primary-active: #fca903 !important;
                --background-color-canvas: #0a0a0a !important;
                --color-accent-primary-hover: #fca903 !important;
                --color-accent-primary-active: #fca903 !important;
                --background-color-information: #7a3a00 !important;
                --icon-color-information: #fc7f03 !important;
              }
            }
          '';

          settings = {
            "browser.startup.homepage" = "https://kagi.com/";
            "privacy.sanitize.sanitizeOnShutdown" = false;
            "privacy.clearOnShutdown_v2.cookiesAndStorage" = false;
            "browser.theme.toolbar-theme" = 0;
            "browser.theme.content-theme" = 0;
            "ui.systemUsesDarkTheme" = 1;
            "layout.css.prefers-color-scheme.content-override" = 0;
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            "sidebar.revamp" = true;
            "sidebar.verticalTabs" = true;
          };
        };

        policies = {
          DisableTelemetry = true;
          DisableFirefoxStudies = true;
          DisableFirefoxAccounts = true;
          DisableFirefoxScreenshots = true;
          DisableForgetButton = true;
          DisableMasterPasswordCreation = true;
          DisableProfileImport = true;
          DisableProfileRefresh = true;
          DisableSetDesktopBackground = true;
          DisablePocket = true;
          DisableFormHistory = true;
          DisablePasswordReveal = true;
          BlockAboutConfig = true;
          BlockAboutProfiles = true;
          BlockAboutSupport = true;
          NewTabPage = false;
          FirefoxHome = {
            Search = true;
            SponsoredTopSites = false;
            Highlights = false;
            Stories = false;
            SponsoredStories = false;
            Snippets = false;
          };

          DisplayMenuBar = "never";
          DontCheckDefaultBrowser = true;
          HardwareAcceleration = false;
          OfferToSaveLogins = false;
          DefaultDownloadDirectory = "${config.home.homeDirectory}/Downloads";

          ExtensionSettings =
            let
              moz = short: "https://addons.mozilla.org/firefox/downloads/latest/${short}/latest.xpi";
            in
            {
              "*".installation_mode = "blocked";

              "uBlock0@raymondhill.net" = {
                install_url = moz "ublock-origin";
                installation_mode = "force_installed";
                updates_disabled = false;
              };

              "search@kagi.com" = {
                install_url = moz "kagi-search-for-firefox";
                installation_mode = "force_installed";
                updates_disabled = false;
              };

              "deArrow@ajay.app" = {
                install_url = moz "dearrow";
                installation_mode = "force_installed";
                updates_disabled = false;
              };

              "sponsorBlocker@ajay.app" = {
                install_url = moz "sponsorblock";
                installation_mode = "force_installed";
                updates_disabled = false;
              };

              #Stylus
              "{7a7a4a92-a2a0-41d1-9fd7-1e92480d612d}" = {
                install_url = moz "styl-us";
                installation_mode = "force_installed";
                updates_disabled = false;
              };

              #Sidebery
              "{3c078156-979c-498b-8990-85f7987dd929}" = {
                install_url = moz "sidebery";
                installation_mode = "force_installed";
                updates_disabled = false;
              };

              "jid0-TgBNh976zF55Pb4ABiM1DXsJV4Q@jetpack" = {
                install_url = moz "startupapps";
                installation_mode = "force_installed";
                updates_disabled = true;
              };

              "firefox-extension@steamdb.info" = {
                install_url = moz "steam-database";
                installation_mode = "force_installed";
                updates_disabled = false;
              };
              "knockoff@knockoff.shopping" = {
                install_url = moz "knockoff-amazon-brand-filter";
                installation_mode = "force_installed";
                updates_disabled = false;
              };

              "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
                install_url = moz "bitwarden-password-manager";
                installation_mode = "force_installed";
                updates_disabled = false;
              };

              "{e6e36c9a-8323-446c-b720-a176017e38ff}" = {
                install_url = moz "torrent-control";
                installation_mode = "force_installed";
                updates_disabled = true;
              };

              "{99c277af-d778-4a0b-9faa-b1d8165f0a55}" = {
                install_url = moz "nicothin-dark-theme";
                installation_mode = "force_installed";
                updates_disabled = true;
              };

            };

          "3rdparty".Extensions = {
            "uBlock0@raymondhill.net".adminSettings = {
              userSettings = rec {
                uiTheme = "dark";
                uiAccentCustom = true;
                uiAccentCustom0 = "#8300ff";
                cloudStorageEnabled = lib.mkForce false;

                importedLists = [
                  "https://filters.adtidy.org/extension/ublock/filters/3.txt"
                  "https://github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
                ];

                externalLists = lib.concatStringsSep "\n" importedLists;
              };

              toOverwrite.filters = [
                "www.youtube.com##ytd-reel-shelf-renderer.ytd-item-section-renderer.style-scope"
                "www.youtube.com##ytd-rich-section-renderer:has(ytm-shorts-lockup-view-model)"
              ];

              selectedFilterLists = [
                "user-filters"
                "CZE-0"
                "adguard-generic"
                "adguard-annoyance"
                "adguard-social"
                "adguard-spyware-url"
                "easylist"
                "easyprivacy"
                "https://github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
                "https://filters.adtidy.org/extension/ublock/filters/3.txt"
                "plowe-0"
                "ublock-abuse"
                "ublock-badware"
                "ublock-filters"
                "ublock-privacy"
                "ublock-quick-fixes"
                "ublock-unbreak"
                "urlhaus-1"
              ];

              hostnameSwitchesString = lib.concatStringsSep "\n" [
                "no-large-media: behind-the-scenes false"
                "no-csp-reports: * true"
                "no-scripting: * true"
              ];
            };
          };
        };
        profiles.default.search = {
          force = true;
          default = "kagi";
          privateDefault = "kagi";

          engines = {
            kagi = {
              name = "Kagi";
              urls = [
                {
                  template = "https://kagi.com/search";
                  params = [
                    {
                      name = "q";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              definedAliases = [ "@kagi" ];
            };

            protondb = {
              name = "ProtonDB";
              urls = [
                {
                  template = "https://www.protondb.com/search";
                  params = [
                    {
                      name = "q";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              definedAliases = [ "@proton" ];
            };

            "Nix Packages" = {
              urls = [
                {
                  template = "https://search.nixos.org/packages";
                  params = [
                    {
                      name = "channel";
                      value = "26.05";
                    }
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@np" ];
            };

            "Nix Options" = {
              urls = [
                {
                  template = "https://search.nixos.org/options";
                  params = [
                    {
                      name = "channel";
                      value = "26.05";
                    }
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@no" ];
            };

            "NixOS Wiki" = {
              urls = [
                {
                  template = "https://wiki.nixos.org/w/index.php";
                  params = [
                    {
                      name = "search";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@nw" ];
            };

            "Noogle" = {
              urls = [
                {
                  template = "https://noogle.dev/";
                  params = [
                    {
                      name = "term";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@noogle" ];
            };
          };
        };
        profiles.default.bookmarks = {
          force = true;
          settings = [
            {
              name = "Bookmarks Bar";
              toolbar = true;
              bookmarks = [
                {
                  name = "E-Mail";
                  url = "https://mail.proton.me";
                  keyword = "mail";
                }
                {
                  name = "Archive of Our Own";
                  url = "https://archiveofourown.org/";
                  keyword = "ao3";
                }
                {
                  name = "Gaming";
                  toolbar = false;
                  bookmarks = [
                    {
                      name = "Backloggd";
                      url = "https://backloggd.com/";
                      keyword = "backlog";
                    }
                    {
                      name = "How Long To Beat";
                      url = "https://howlongtobeat.com";
                      keyword = "hltb";
                    }
                  ];
                }
                {
                  name = "Shopping";
                  toolbar = false;
                  bookmarks = [
                    {
                      name = "SteamDB";
                      url = "https://steamdb.info/";
                      keyword = "stb";
                    }
                    {
                      name = "Steam Hardware Hub";
                      url = "https://steamhardware.io";
                      keyword = "steamhw";
                    }
                    {
                      name = "IsThereAnyDeal?";
                      url = "https://www.isthereanydeal.com";
                      keyword = "itad";
                    }
                    {
                      name = "Unofficial Deals";
                      url = "https://gg.deals";
                      keyword = "keydeal";
                    }
                    {
                      name = "Deku Deals";
                      url = "https://www.dekudeals.com";
                      keyword = "deku";
                    }
                    {
                      name = "Humble Bundle";
                      url = "https://www.humblebundle.com";
                      keyword = "humble";
                    }
                    {
                      name = "Exchange";
                      url = "https://swap.bitania.com";
                      keyword = "coin";
                    }
                  ];
                }
                {
                  name = "Torrents";
                  toolbar = false;
                  bookmarks = [
                    {
                      name = "qBit - nyx-nixos";
                      url = "https://qbit.olympus.moe";
                      keyword = "qbit";
                    }
                    {
                      name = "SkullXDCC";
                      url = "https://xdcc-search.com/";
                      keyword = "skull";
                    }
                    {
                      name = "XDDC.eu";
                      url = "https://xdcc.eu";
                      keyword = "skulleu";
                    }
                    {
                      name = "FMHY";
                      url = "https://fmhy.net";
                      keyword = "fmhy";
                    }
                    {
                      name = "GOG Games Downloader";
                      url = "https://gog-games.to";
                      keyword = "gog";
                    }
                    {
                      name = "FitGirl Repacks";
                      url = "https://fitgirl-repacks.site";
                      keyword = "fitgirl";
                    }
                    {
                      name = "Private Trackers";
                      toolbar = false;
                      bookmarks = [
                        {
                          name = "GazelleGames";
                          url = "https://gazellegames.net";
                          keyword = "ggn";
                        }
                        {
                          name = "SeedPool";
                          url = "https://seedpool.org";
                          keyword = "seed";
                        }
                        {
                          name = "Orpheus Network";
                          url = "https://orpheus.network/";
                          keyword = "orph";
                        }
                      ];
                    }
                    {
                      name = "Public Trackers";
                      toolbar = false;
                      bookmarks = [
                        {
                          name = "nyaa.si";
                          url = "https://nyaa.si";
                          keyword = "nya";
                        }
                      ];
                    }
                    {
                      name = "Tools";
                      toolbar = false;
                      bookmarks = [
                        {
                          name = "GGn Userscripts";
                          url = "https://gazellegames.net/wiki.php?action=article&id=633";
                          keyword = "ggnscript";
                        }
                        {
                          name = "GGn Mass Downloader";
                          url = "https://gazellegames.net/wiki.php?action=article&id=445";
                          keyword = "ggndown";
                        }
                        {
                          name = "GGn Status";
                          url = "https://ggn.trackerstatus.info";
                          keyword = "ggnstat";
                        }
                      ];
                    }
                  ];
                }
                {
                  name = "HomeLab";
                  toolbar = false;
                  bookmarks = [
                    {
                      name = "Jellyfin";
                      url = "https://stream.puppygirls.net";
                      keyword = "stream";
                    }
                    {
                      name = "Navidrome";
                      url = "https://music.puppygirls.net";
                      keyword = "music";
                    }
                    {
                      name = "seerr";
                      url = "https://seerr.puppygirls.net";
                      keyword = "seerr";
                    }
                    {
                      name = "radarr";
                      url = "https://radarr.puppygirls.net";
                      keyword = "radarr";
                    }
                    {
                      name = "sonarr";
                      url = "https://sonarr.puppygirls.net";
                      keyword = "sonarr";
                    }
                    {
                      name = "BunnyDNS";
                      url = "https://www.bunny.net/dns/";
                      keyword = "bunny";
                    }
                  ];
                }
                {
                  name = "Development";
                  toolbar = false;
                  bookmarks = [
                    {
                      name = "NixOS Wiki";
                      url = "https://wiki.nixos.org";
                    }
                    {
                      name = "Nixpkgs Manual";
                      url = "https://nixos.org/manual/nixpkgs/stable/";
                      keyword = "manpkg";
                    }
                    {
                      name = "XP.css";
                      url = "https://botoxparty.github.io/XP.css/";
                      keyword = "xpcss";
                    }
                  ];
                }
                {
                  name = "Social";
                  toolbar = false;
                  bookmarks = [
                    {
                      name = "The Lounge";
                      url = "http://[::1]:9000";
                      keyword = "irc";
                    }
                  ];
                }
                {
                  name = "Information";
                  toolbar = false;
                  bookmarks = [
                    {
                      name = "Linux";
                      toolbar = false;
                      bookmarks = [
                        {
                          name = "Nixpkgs Manual";
                          url = "https://www.nixos.org/manual/nixpkgs/stable";
                          keyword = "npman";
                        }
                        {
                          name = "Command Line Gems";
                          url = "https://www.commandlinefu.com/commands/browse";
                          keyword = "cmd";
                        }
                        {
                          name = "The Linux Documentation Project";
                          url = "https://tldp.org/index.html";
                          keyword = "tldp";
                        }
                        {
                          name = "pure-sh-bible";
                          url = "https://github.com/dylanaraps/pure-sh-bible";
                          keyword = "sh";
                        }
                        {
                          name = "pure-bash-bible";
                          url = "https://github.com/dylanaraps/pure-bash-bible";
                          keyword = "bash";
                        }
                        {
                          name = "OverTheWire";
                          url = "https://overthewire.org/wargames/";
                          keyword = "otw";
                        }
                      ];
                    }
                    {
                      name = "FOSS/Privcy";
                      toolbar = false;
                      bookmarks = [
                        {
                          name = "FUTO Self Managed Guide";
                          url = "https://wiki.futo.org/index.php/Introduction_to_a_Self_Managed_Life:_a_13_hour_%26_28_minute_presentation_by_FUTO_software";
                          keyword = "futo";
                        }
                      ];
                    }
                    {
                      name = "Awesome Lists";
                      url = "https://github.com/sindresorhus/awesome?tab=readme-ov-file";
                      keyword = "awelist";
                    }
                  ];
                }
              ];
            }
          ];
        };
      };
    };

  flake.homeModules.syncthing =
    {
      config,
      osConfig,
      lib,
      ...
    }:
    let
      address = {
        "circe-nixos" = "192.168.10.2";
        "dionysus-nixos" = "192.168.10.3";
        "ariadne-nixos" = "192.168.10.4";
        "athena-nixos" = "192.168.10.1";
      };

      ffxivIgnorePatterns = [
        "!.stignore"
        "!accounts.json"
        "!secrets.json"
        "!cfgcopy"
        "!ffxivConfig"
        "ffxivConfig/FFXIV.cfg"
        "ffxivConfig/FFXIV.cfg.old"
        "!pluginConfigs"
        "!installedPlugins"
        "!dalamudConfig.json"
        "!dalamudUI.ini"
        "!launcherUI.ini"
        "!FFXIV_CHR004000174C7A37AE"
        "pluginConfigs/LightlessSync/tracelog"
        "*"
      ];
    in
    {
      home.file.".xlcore/.stignore" = {
        text = lib.concatStringsSep "\n" (ffxivIgnorePatterns ++ [ "" ]);
        force = true;
      };
      services.syncthing = {
        enable = true;
        overrideFolders = true;

        cert = config.sops.secrets."syncthing/${osConfig.networking.hostName}/cert".path;
        key = config.sops.secrets."syncthing/${osConfig.networking.hostName}/key".path;

        settings = {
          devices = {
            athena-nixos = {
              id = "JKIY2Y5-V62NP54-PUGNOIZ-N3VQ4QY-7LJ4T4T-WEQWEDX-B7RIP74-J24IGQM";
            };
            circe-nixos = {
              id = "ECLW26H-2JWNNZX-YUWT42U-CYNARNX-SJRMMXA-XA2I7KD-ATCMTX2-4JXJNAP";
            };
            dionysus-nixos = {
              id = "AQSHDSY-3I6HO7B-XJTWCSU-5MBSCSL-AU4BWKN-PQUDFE2-YVBZT6R-25G7RAI";
            };
            ariadne-nixos = {
              id = "Z6NPUDI-PZ46LWD-6WJ2AN4-TFTS3ST-VSR4TBS-JSU73RB-MYOPXP7-2ISDWAR";
            };
            nyx-nixos = {
              id = "T5XG4ZF-FYS5II7-JJH5274-CZF2CDG-QDDTASR-FZH7FCO-TQA6UV2-KDFTYQB";
            };
          };
          folders = {
            "FFXIV" = {
              id = "FFXIV";
              path = "${config.home.homeDirectory}/.xlcore";
              devices = [
                "circe-nixos"
                "nyx-nixos"
                "dionysus-nixos"
                "athena-nixos"
                "ariadne-nixos"
              ];
              ignorePatterns = [
                "!.stignore"
                "!accounts.json"
                "!secrets.json"
                "!cfgcopy"
                "!ffxivConfig"
                "ffxivConfig/FFXIV.cfg"
                "ffxivConfig/FFXIV.cfg.old"
                "!pluginConfigs"
                "!installedPlugins"
                "!dalamudConfig.json"
                "!dalamudUI.ini"
                "!launcherUI.ini"
                "!FFXIV_CHR004000174C7A37AE"
                "pluginConfigs/LightlessSync/tracelog"
                "*"
              ];
            };
          };
        };

        guiAddress = "${address.${osConfig.networking.hostName}}:8384";
        guiCredentials = {
          username = "foxtrot";
          passwordFile = "${config.sops.secrets."syncthing/pass".path}";
        };
      };
    };
}
