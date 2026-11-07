{ inputs, self, ... }:
{
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
            "glm-5.3-flash"
            "deepseek-v4.1-flash"
            "openrouter/z-ai/glm-5.3-flash"
            "llama.cpp/*"
            "bansos/*"
          ];
          defaultThinkingLevel = "low";
          packages = [
            "npm:pi-death-loop-guard"
            "npm:pi-web-access"
            "npm:@juicesharp/rpiv-todo"
            "npm:@juicesharp/rpiv-ask-user-question"
            "npm:pi-bansos"
            "npm:pi-subagents"
            "${inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.pi-agent-modes}"
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
                  id = "z-ai/glm-5.3-flash";
                  name = "Z.ai: GLM 5.3 Flash";
                  api = "openai-completions";
                  baseUrl = "https://openrouter.ai/api/v1";
                  reasoning = true;
                  input = [
                    "text"
                    "image"
                  ];
                  cost = {
                    input = 0.0285;
                    output = 0.0923;
                    cacheRead = 0.0285;
                    cacheWrite = 0;
                  };
                  contextWindow = 1048576;
                  maxTokens = 131072;
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
          Athena foxtrot@athena-nixos.olympus.netbird · Circe foxtrot@circe-nixos.olympus.netbird ·
          Dionysus deck@dionysus-nixos.olympus.netbird · Ariadne deck@ariadne-nixos.olympus.netbird ·
          Nyx server@nyx-nixos.olympus.netbird · Aether server@aether-nixos.olympus.netbird
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
        ".pi/agent/agents/cheap-scout.md".source = "${
          inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.assets
        }/share/assets/pi/agents/cheap-scout.md";
        ".pi/agent/extensions/subagent/config.json".text = builtins.toJSON { toolActivation = "eager"; };
        ".pi/agent/extensions/vm-test".source = "${
          inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.assets
        }/share/assets/pi/vm-test";
      };

      home.file.".pi/agent/modes.config.json".text =
        let
          delegationTools = [
            "subagent"
            "subagent_supervisor"
            "bg_wait"
          ];
          readOnlyTools = [
            "ask_user_question"
            "codemode"
            "fetch_content"
            "get_search_content"
            "source_check"
            "todo"
            "tool_search"
            "web_enable"
            "web_search"
          ]
          ++ delegationTools;
          gitReadOnlyInstructions = "bash IS available in this mode for read-only commands, including read-only git: git log, git status, git diff, git show, git blame. You can and should use these to inspect commit history. Run git commands directly (the repository is the working directory) — never use 'cd ... && ...' chains, semicolon-separated command lists, 'git -C <path>', or output redirects like '2>/dev/null'; the read-only guard rejects those forms. Mutating git commands (add, commit, push, pull, fetch, checkout, restore, etc.) are blocked.";
        in
        builtins.toJSON {
          modes = {
            ask.allowTools = readOnlyTools;
            ask.thinkingLevel = null;
            ask.extraInstructions = gitReadOnlyInstructions;
            plan.allowTools = readOnlyTools ++ [ "pi_modes_plan_complete" ];
            plan.thinkingLevel = null;
            plan.extraInstructions = gitReadOnlyInstructions;
            review.allowTools = readOnlyTools;
            review.thinkingLevel = null;
            review.extraInstructions = gitReadOnlyInstructions;
          };
        };

    };
}
