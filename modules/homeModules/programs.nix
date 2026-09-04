{ inputs, self, ... }:
{

  flake.homeModules.common = { pkgs, ... }: {
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/unityhub" = "unityhub.desktop";
      };
    };

    xdg.configFile."mimeapps.list".force = true;

    home.packages = with pkgs; [
      kitty
      zellij
      fastfetch
      kdePackages.dolphin
      unrar
      p7zip
      (bottles.override {
        removeWarningPopup = true;
      })
      libreoffice-qt-fresh
      wine
      winetricks
      protontricks
      filezilla
      feather
    ];

    programs.kitty = {
      enable = true;
      settings = {
        confirm_os_window_close = 0;
      };
    };
  };

  flake.homeModules.nixvim = { pkgs, lib, inputs, ... }: {
    imports = [ inputs.nixvim.homeModules.nixvim ];
    programs.nixvim = {
      enable = true;
      enableMan = true;
      nixpkgs.source = inputs.nixpkgs;
      plugins = {
        lazy = {
          enable = true;
          settings = {

          };
        };
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
      };
      opts = {
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
      extraConfigVim = ''
        if has('clipboard')
          set clipboard=unnamedplus
        end
      '';
    };
  };

  flake.homeModules.nixcord = { inputs, pkgs, config, lib, ... }: {
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

    programs.nixcord = {
      enable = true;

      discord = {
        enable = true;
        installPackage = false;
        krisp.enable = true;
        vencord.enable = true;
        commandLineArgs = [
          "--enable-features=WebRTCPipeWireCapturer"
          "--disable-gpu"
        ];
        settings = {
          openasar = {
            setup = true;
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

  flake.homeModules.opencode = { lib, pkgs, pkgs-unstable, config, ... }: let
    claudeRules = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/sisyphusse1-ops/claude-code-pro-pack/refs/heads/main/CLAUDE.md";
      hash = "sha256-wayXk5qtd+mmKNUPlqKRjyHQGml92kqbng+LTy26GJs=";
    };

    homeDir = config.home.homeDirectory;
  in {
    programs.opencode = {
      enable = true;
      package = pkgs-unstable.opencode;

      settings = {
        model = "openrouter/z-ai/glm-5.3-flash";
        small_model = "openrouter/z-ai/glm-5.3-flash";
        default_agent = "code-reviewer";

        permission = {
          bash = {
            "ls *" = "allow";
            "grep *" = "allow";
            "find *" = "allow";
            "git *" = "allow";
            "stat *" = "allow";
            "readlink *" = "allow";
            "ps *" = "allow";
            "busctl *" = "allow";
            "curl *" = "allow";
            "which *" = "allow";
            "nix *" = "allow";
            "sudo nix *" = "allow";
            "nix-instantiate *" = "allow";
            "nix-store *" = "allow";
            "nix-build *" = "allow";
            "nix-shell *" = "allow";
            "nix-env *" = "allow";
            "nixos-rebuild *" = "allow";
            "sudo nixos-rebuild *" = "allow";
            "home-manager *" = "allow";
            "systemctl *" = "allow";
            "sudo systemctl *" = "allow";
            "journalctl *" = "allow";
            "sudo journalctl *" = "allow";
          };
          read = {
            "${homeDir}/olympus-nixos/**" = "allow";
            "/etc/**" = "allow";
            "/run/**" = "allow";
            "/nix/store/**" = "allow";
          };
          grep = {
            "${homeDir}/olympus-nixos/**" = "allow";
          };
        };
      };

      context = ''
        ${builtins.readFile claudeRules}

        # Memory / Persistent Context

        ## Code Style Preferences

        Do not add inline comments to code. Explain changes in commit messages instead.

        ## Session Workflow

        At the start of every session, before reading or modifying any files,
        check that the current repository is up to date:

            git pull

        Do this for any repo being worked in, not just olympus-nixos.
        This avoids working on stale code and prevents conflicts on push.

        `git add` is allowed when required (e.g. staging a new file before a
        rebuild). But `git commit`, `git commit --amend`, and `git push` must
        NEVER be run unless the user has explicitly asked for it in that message.
        When in doubt, stage the files and stop — describe what would be committed
        and wait for the instruction.

        ## User Context

        Always use the **current user's** home directory — whoever is running
        opencode at the time. Do NOT hardcode /home/foxtrot.

        - In Nix expressions: use `config.home.homeDirectory`
        - In shell commands: use $HOME or ~
        - In reasoning: infer from `whoami` / the active session

        The current deploying user happens to be "foxtrot" (/home/foxtrot),
        but this should be treated as an example, not a constant.

        ## Nix / Flake Gotchas (olympus-nixos)

        Any changes to opencode's own permissions, context, agent definition,
        or settings must be made in:

            ~/olympus-nixos/home/programs/opencode.nix

        Do NOT write to ~/.config/opencode/ directly — those are nix store
        symlinks and writes will fail or be lost on the next rebuild.

        ALL .config/opencode/ files managed by home-manager are symlinks into
        the nix store and cannot be written to directly.

        After any config change, rebuild:

            sudo nixos-rebuild switch --flake ~/olympus-nixos

        Brand-new files must be `git add`ed before rebuild can see them.
        Nix flakes only evaluate files tracked by git.

        When updating a flake input, only update that specific input:

            nix flake update <input-name>   # correct
            nix flake update                # wrong — updates everything
      '';

      agents = {
        code-reviewer = ''
          ---
          description: Plan mode - think and propose a plan, then hand off to build for execution
          mode: primary
          model: openrouter/z-ai/glm-5.3-flash
          permission:
            edit: deny
            read:
              "${homeDir}/**": allow
              "/home/server/**": allow
              "/nix/store/**": allow
            external_directory:
              "${homeDir}/**": allow
              "/home/server/**": allow
              "/nix/store/**": allow
          ---

          You are a planner. Think step by step and come up with a plan.
          Ask the user questions if anything is unclear. Do not edit
          files. Do not write code. Present your plan for approval
          before doing any work.

          You are a lesbian and have a wonderful wife whom you love.
        '';
      };
    };
  };

  flake.homeModules.download = { pkgs, inputs, ... }: {
    home.packages =
      (with pkgs; [

      ]) ++ (with inputs.luxxy-pkgs.packages.${pkgs.stdenv.hostPlatform.system}; [
        (jdownloader.override {
          darkTheme = true;
        })
      ]);
  };

  flake.homeModules.easyeffects = { ... }: {
    services.easyeffects = {
      enable = true;
      preset = "BaseAudio";
      extraPresets = {
        BaseAudio = {
          "input" = {
            "blocklist" = [ ];
            "compressor#0" = {
              "attack" = 15.0;
              "boost-amount" = 0.0;
              "boost-threshold" = -72.0;
              "bypass" = false;
              "dry" = -80.01;
              "hpf-frequency" = 10.0;
              "hpf-mode" = "Off";
              "input-gain" = 0.0;
              "input-to-link" = 0.0;
              "input-to-sidechain" = 0.0;
              "knee" = -6.0;
              "link-to-input" = 0.0;
              "link-to-sidechain" = 0.0;
              "lpf-frequency" = 20000.0;
              "lpf-mode" = "Off";
              "makeup" = 3.0;
              "mode" = "Downward";
              "output-gain" = 0.0;
              "ratio" = 3.0;
              "release" = 200.0;
              "release-threshold" = -40.0;
              "sidechain" = {
                "lookahead" = 0.0;
                "mode" = "RMS";
                "preamp" = 0.0;
                "reactivity" = 10.0;
                "source" = "Middle";
                "stereo-split-source" = "Left/Right";
                "type" = "Feed-forward";
              };
              "sidechain-to-input" = 0.0;
              "sidechain-to-link" = 0.0;
              "stereo-split" = false;
              "threshold" = -18.0;
              "wet" = 0.0;
            };
            "deepfilternet#0" = {
              "attenuation-limit" = 100.0;
              "bypass" = false;
              "input-gain" = 0.0;
              "max-df-processing-threshold" = 20.0;
              "max-erb-processing-threshold" = 30.0;
              "min-processing-buffer" = 0;
              "min-processing-threshold" = 5.0;
              "output-gain" = 0.0;
              "post-filter-beta" = 0.019999999552965164;
            };
            "deesser#0" = {
              "bypass" = false;
              "detection" = "RMS";
              "f1-freq" = 4000.0;
              "f1-level" = -6.0;
              "f2-freq" = 8000.0;
              "f2-level" = -6.0;
              "f2-q" = 1.5;
              "input-gain" = 0.0;
              "laxity" = 15;
              "makeup" = 0.0;
              "mode" = "Split";
              "output-gain" = 0.0;
              "ratio" = 3.0;
              "sc-listen" = false;
              "threshold" = -22.0;
            };
            "equalizer#0" = {
              "balance" = 0.1;
              "bypass" = false;
              "input-gain" = 0.0;
              "left" = {
                "band0" = {
                  "frequency" = 80.0;
                  "gain" = 0.0;
                  "mode" = "RLC (BT)";
                  "mute" = false;
                  "q" = 0.7;
                  "slope" = "x2";
                  "solo" = false;
                  "type" = "Hi-pass";
                  "width" = 4.0;
                };
                "band1" = {
                  "frequency" = 220.0;
                  "gain" = -2.0;
                  "mode" = "RLC (MT)";
                  "mute" = false;
                  "q" = 0.7;
                  "slope" = "x1";
                  "solo" = false;
                  "type" = "Bell";
                  "width" = 4.0;
                };
                "band2" = {
                  "frequency" = 350.0;
                  "gain" = -2.0;
                  "mode" = "BWC (MT)";
                  "mute" = false;
                  "q" = 1.2;
                  "slope" = "x2";
                  "solo" = false;
                  "type" = "Bell";
                  "width" = 4.0;
                };
                "band3" = {
                  "frequency" = 3500.0;
                  "gain" = 2.0;
                  "mode" = "BWC (BT)";
                  "mute" = false;
                  "q" = 0.9;
                  "slope" = "x2";
                  "solo" = false;
                  "type" = "Bell";
                  "width" = 4.0;
                };
                "band4" = {
                  "frequency" = 10000.0;
                  "gain" = 2.0;
                  "mode" = "LRX (MT)";
                  "mute" = false;
                  "q" = 0.7;
                  "slope" = "x1";
                  "solo" = false;
                  "type" = "Hi-shelf";
                  "width" = 4.0;
                };
              };
              "mode" = "IIR";
              "num-bands" = 5;
              "output-gain" = 0.0;
              "pitch-left" = 0.0;
              "pitch-right" = 0.0;
              "right" = {
                "band0" = {
                  "frequency" = 80.0;
                  "gain" = 0.0;
                  "mode" = "RLC (BT)";
                  "mute" = false;
                  "q" = 0.7;
                  "slope" = "x2";
                  "solo" = false;
                  "type" = "Hi-pass";
                  "width" = 4.0;
                };
                "band1" = {
                  "frequency" = 220.0;
                  "gain" = -2.0;
                  "mode" = "RLC (MT)";
                  "mute" = false;
                  "q" = 0.7;
                  "slope" = "x1";
                  "solo" = false;
                  "type" = "Bell";
                  "width" = 4.0;
                };
                "band2" = {
                  "frequency" = 350.0;
                  "gain" = -2.0;
                  "mode" = "BWC (MT)";
                  "mute" = false;
                  "q" = 1.2;
                  "slope" = "x2";
                  "solo" = false;
                  "type" = "Bell";
                  "width" = 4.0;
                };
                "band3" = {
                  "frequency" = 3500.0;
                  "gain" = 2.0;
                  "mode" = "BWC (BT)";
                  "mute" = false;
                  "q" = 0.9;
                  "slope" = "x2";
                  "solo" = false;
                  "type" = "Bell";
                  "width" = 4.0;
                };
                "band4" = {
                  "frequency" = 10000.0;
                  "gain" = 2.0;
                  "mode" = "LRX (MT)";
                  "mute" = false;
                  "q" = 0.7;
                  "slope" = "x1";
                  "solo" = false;
                  "type" = "Hi-shelf";
                  "width" = 4.0;
                };
              };
              "split-channels" = false;
            };
            "gate#0" = {
              "attack" = 5.0;
              "bypass" = false;
              "curve-threshold" = -50.0;
              "curve-zone" = -2.0;
              "dry" = -80.01;
              "hpf-frequency" = 10.0;
              "hpf-mode" = "Off";
              "hysteresis" = true;
              "hysteresis-threshold" = -3.0;
              "hysteresis-zone" = -1.0;
              "input-gain" = 0.0;
              "input-to-link" = 0.0;
              "input-to-sidechain" = 0.0;
              "link-to-input" = 0.0;
              "link-to-sidechain" = 0.0;
              "lpf-frequency" = 20000.0;
              "lpf-mode" = "Off";
              "makeup" = 1.0;
              "output-gain" = 0.0;
              "reduction" = -12.0;
              "release" = 250.0;
              "sidechain" = {
                "lookahead" = 0.0;
                "mode" = "RMS";
                "preamp" = 0.0;
                "reactivity" = 10.0;
                "source" = "Middle";
                "stereo-split-source" = "Left/Right";
                "type" = "Internal";
              };
              "sidechain-to-input" = 0.0;
              "sidechain-to-link" = 0.0;
              "stereo-split" = false;
              "wet" = -1.0;
            };
            "limiter#0" = {
              "alr" = false;
              "alr-attack" = 5.0;
              "alr-knee" = 0.0;
              "alr-release" = 50.0;
              "attack" = 2.0;
              "bypass" = false;
              "dithering" = "16bit";
              "gain-boost" = false;
              "input-gain" = 0.0;
              "input-to-link" = 0.0;
              "input-to-sidechain" = 0.0;
              "link-to-input" = 0.0;
              "link-to-sidechain" = 0.0;
              "lookahead" = 2.0;
              "mode" = "Herm Wide";
              "output-gain" = 0.0;
              "oversampling" = "None";
              "release" = 5.0;
              "sidechain-preamp" = 0.0;
              "sidechain-to-input" = 0.0;
              "sidechain-to-link" = 0.0;
              "sidechain-type" = "Internal";
              "stereo-link" = 100.0;
              "threshold" = -1.5;
            };
            "plugins_order" = [
              "rnnoise#0"
              "deepfilternet#0"
              "gate#0"
              "equalizer#0"
              "compressor#0"
              "deesser#0"
              "limiter#0"
            ];
            "rnnoise#0" = {
              "bypass" = false;
              "enable-vad" = false;
              "input-gain" = 0.0;
              "model-name" = "\"\"";
              "output-gain" = 0.0;
              "release" = 20.0;
              "use-standard-model" = true;
              "vad-thres" = 30.0;
              "wet" = 0.0;
            };
          };
        };
      };
    };
  };

  flake.homeModules.launchers = { pkgs, inputs, ... }: let 
    gamemoderun = pkgs.writeShellScriptBin "gamemoderun" ''
      exec env \
        ${pkgs.gamemode}/bin/gamemoderun "$@"
    '';

    wrapNoHardened =
      pkg: binName:
      let
        wrapper = pkgs.writeShellScript "${binName}-no-hardened" ''
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
  in {
    home.packages = [
      gamemoderun
      pkgs.prismlauncher
      pkgs.moonlight-qt
      inputs.elysia.packages.x86_64-linux.default
      (wrapNoHardened pkgs.xivlauncher "XIVLauncher.Core")
      (pkgs.olympus.override { celesteWrapper = "steam-run"; })
      pkgs.r2modman
      (wrapNoHardened pkgs.heroic "heroic")
      (wrapNoHardened pkgs.azahar "azahar")
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
      weechat
    ];
  };

  flake.homeModules.creation = { pkgs, ... }: let
    unityhubNoSandbox = pkgs.writeShellScriptBin "unityhub-launcher" ''
      exec ${pkgs.unityhub}/bin/unityhub --no-sandbox "$@"
    '';
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
  in {
    xdg.desktopEntries.unityhub = {
      name = "Unity Hub";
      exec = "${unityhubNoSandbox}/bin/unityhub-launcher %U";
      terminal = false;
      type = "Application";
      icon = "unityhub";
      comment = "The Official Unity Hub";
      categories = [ "Development" ];
      mimeType = [ "x-scheme-handler/unityhub" ];
      noDisplay = false;
    };

    home.packages = with pkgs; [
      gimp-with-plugins
      gpu-screen-recorder
      gpu-screen-recorder-gtk
      bitwig-studio
      kdePackages.kdenlive
      handbrake
      rawtherapee
      ansel
      unityhub
      blender
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
      categories = [ "Video" "AudioVideo" "Graphics" ];
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

  flake.homeModules.browsers = { pkgs, config, lib, inputs, ... }: let
    hmFirefox = config.programs.firefox.finalPackage;
    emptyFile = pkgs.writeText "empty" "";
    firefoxNoHardened = pkgs.writeShellScriptBin "firefox" ''
        exec ${pkgs.util-linux}/bin/unshare --mount --user --map-root-user \
          ${pkgs.bash}/bin/bash -c "${pkgs.util-linux}/bin/mount --bind ${emptyFile} /etc/ld-nix.so.preload && exec ${hmFirefox}/bin/firefox \"\$@\"" -- "$@"
    '';
  in {
    home.packages = [
      (lib.hiPrio firefoxNoHardened)
    ];

    programs.firefox = {
      enable = true;
      package = pkgs.firefox;

      profiles."default" = {
        name = "default";
        userChrome = ''
          .tab-text { font-size: 14px !important; }
        '';
        settings = {
          "browser.startup.homepage" = "https://kagi.com/";
          "browser.theme.toolbar-theme" = 0;
          "browser.theme.content-theme" = 0;
          "ui.systemUsesDarkTheme" = 1;
          "layout.css.prefers-color-scheme.content-override" = 0;
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

            "jid0-TgBNh976zF55Pb4ABiM1DXsJV4Q@jetpack" = {
              install_url = moz "startupapps";
              installation_mode = "force_installed";
              updates_disabled = true;
            };

            "PipedRedirect@janigma.com" = {
              install_url = moz "pipedredirectjanigma";
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

            "{aecec67f-0d10-4fa7-b7c7-609a2db280cf}" = {
              install_url = moz "violentmonkey";
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
                "https:#filters.adtidy.org/extension/ublock/filters/3.txt"
                "https:#github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
              ];

              externalLists = lib.concatStringsSep "\n" importedLists;
            };

            selectedFilterLists = [
              "CZE-0"
              "adguard-generic"
              "adguard-annoyance"
              "adguard-social"
              "adguard-spyware-url"
              "easylist"
              "easyprivacy"
              "https:#github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
              "plowe-0"
              "ublock-abuse"
              "ublock-badware"
              "ublock-filters"
              "ublock-privacy"
              "ublock-quick-fixes"
              "ublock-unbreak"
              "urlhaus-1"
            ];
          };
          # Torrent Control Settings
          "{e6e36c9a-8323-446c-b720-a176017e38ff}".adminSettings = {

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
}
