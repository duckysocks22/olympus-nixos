{ inputs, self, ... }:
{
  flake.homeModules.fish =
    {
      inputs,
      config,
      pkgs,
      lib,
      ...
    }:
    {
      home.packages = with pkgs; [
        grc
        fzf
      ];

      programs.fish = {
        enable = true;
        package = pkgs.fish;

        plugins = [
          {
            name = "grc";
            src = pkgs.fishPlugins.grc.src;
          }
          {
            name = "fzf-fish";
            src = pkgs.fishPlugins.fzf-fish.src;
          }
          {
            name = "done";
            src = pkgs.fishPlugins.done.src;
          }
          {
            name = "tide";
            src = pkgs.fishPlugins.tide.src;
          }
          {
            name = "forgit";
            src = pkgs.fishPlugins.forgit.src;
          }
        ];

        functions = {
          rebuild = ''
            switch "$argv[1]"
              case -h --help
                echo "Usage: rebuild [flag]"
                echo "  -u, --update"
                return 0
              case -u --update
                nix flake update --flake ~/olympus-nixos
                nh os switch
                attic push main /run/current-system
              case '*'
                nh os switch
            end
          '';
          encode = ''
            switch "$argv[1]"
              case -h --help
                echo "Usage: encode [INPUT] [OUTPUT]"
                echo "Used to encode media via HandBrake with set parameters."
                return 0
            end

            HandBrakeCLI --input "$argv[1]" --output "$argv[2]" --encoder x265 -x pools=6 --all-audio --all-subtitles --aencoder opus
          '';
          bulkencode = ''
            switch "$argv[1]"
              case -h --help
                echo "Usage: bulkencode [INPUT_DIR] [OUTPUT_DIR]"
                echo "Used to bulk encode a directory of media via HandBrake with set parameters."
                return 0
            end

            cd "$argv[1]"
            for f in *.mkv
              HandBrakeCLI --input "$f" --output "$argv[2]/$f" --encoder x265 -x pools=6 --all-audio --all-subtitles --aencoder opus
            end
          '';
          psxrip = ''
            switch "$argv[1]"
              case -h --help
                echo "Usage: psxrip [GAME_NAME]"
                echo "Rips PSX game to current directory"
            end

            cdrdao read-cd --read-raw --read-subchan rw_raw --datafile $1.bin --device /dev/sr0 --driver generic-mmc-raw $1.toc
          '';
          firefoxid = ''
            switch "$argv[1]"
              case -h --help
                echo "Usage: firefoxid [EXTENSION_NAME] or [EXTENSION_URL]"
                echo "Used to find the UUID of a Firefox Extension"
            end

            nix run github:tupakkatapa/mozid -- "$argv[1]"
          '';
          debugfox = ''
            set -l keep false
            switch "$argv[1]"
              case -h --help
                echo "Usage: debugfox [-k|--keep] [FIREFOX_ARGS...]"
                echo "Launches Firefox on a throwaway copy of the LibreWolf profile with DevTools remote debugging and the Browser Toolbox enabled."
                echo "LibreWolf cannot do this itself: its bundled mozilla.cfg pins devtools.debugger.remote-enabled to false before the command line is handled."
                echo "The debugger server listens on 127.0.0.1:6000 for web and tab debugging; the Browser Toolbox opens for chrome and add-on debugging."
                echo "  -k, --keep  keep the temporary profile directory after Firefox exits"
                return 0
              case -k --keep
                set keep true
            end

            set -l extra $argv
            if test $keep = true
              set extra $argv[2..-1]
            end

            set -l src "$HOME/.librewolf/default"
            if not test -d "$src"
              echo "debugfox: no profile found at $src" >&2
              return 1
            end

            set -l flake "$HOME/olympus-nixos"
            set -l sys (uname -m)-linux
            set -l ff (nix build --no-link --print-out-paths --impure --expr "let f = builtins.getFlake \"$flake\"; in f.inputs.nixpkgs.legacyPackages.$sys.firefox" | tail -1)
            if test -z "$ff"
              echo "debugfox: could not resolve firefox from $flake" >&2
              return 1
            end

            set -l dbg (mktemp -d)
            command cp -a "$src"/. "$dbg"/
            command rm -f "$dbg/user.js" "$dbg/lock" "$dbg/.parentlock"
            printf '%s\n' \
              'user_pref("devtools.debugger.remote-enabled", true);' \
              'user_pref("devtools.chrome.enabled", true);' \
              'user_pref("devtools.debugger.prompt-connection", false);' > "$dbg/user.js"

            echo "debugfox: profile $dbg"
            echo "debugfox: web debugging on 127.0.0.1:6000, Browser Toolbox opens at startup"

            ${pkgs.util-linux}/bin/unshare --mount --user --map-root-user \
              ${pkgs.runtimeShell} -c '
                ${pkgs.util-linux}/bin/mount --bind /dev/null /etc/ld-nix.so.preload
                exec "$1/bin/firefox" --profile "$2" --no-remote --start-debugger-server 6000 --jsdebugger "''${@:3}"
              ' debugfox "$ff" "$dbg" $extra

            if test $keep = true
              echo "debugfox: profile kept at $dbg"
            else
              command rm -rf "$dbg"
            end
          '';
          securewipe = ''
            switch "$argv[1]"
              case -h --help
                echo "Usage: securewipe [DISK]"
                echo "Used to zero out and randomize data on drive to securely wipe all data."
            end

            sudo dd if=/dev/zero of="$argv[1]" bs=512 status="progress"
          '';
          vm = ''
            switch "$argv[1]"
              case -h --help
                echo "Usage: vm [HOST_NAME]"
                echo "Builds and then launches a Virtual Machine using the configuration of the specified host"
            end

            cd ~/olympus-nixos
            nix run ".#nixosConfigurations.$argv[1].config.system.build.vmWithDisko" -- -display gtk,gl=on -vga none -device virtio-gpu-gl-pci
          '';
        };

        shellAliases = {
          vi = "nvim";
          par = ''
            cd ${config.home.homeDirectory}/olympus-nixos
            git pull
            nh os switch
            attic push main /run/current-system
          '';
          cleanup = "nh clean all";
          hb = "HandBrakeCLI";
          buildiso = ''
            cd ~/olympus-nixos
            nix build -L .#nixosConfigurations.olympus-iso.config.system.build.isoImage
          '';
          weather = ''curl "wttr.in/?u"'';
          ai-commit = ''git commit --trailer "Co-Authored-By: Deepseek-v4.1-Flash <noreply@deepseek.com>"'';
          cachestore = "attic push --ignore-upstream-cache-filter main $(ls -d /nix/store/*/ | grep -v fake_nixpkgs)";
          cachesys = "attic push main /run/current-system";
          cp = "rsync --progress --stats";
        };

        shellInit = ''
          export FZF_DEFAULT_OPS="${config.home.sessionVariables.FZF_DEFAULT_OPTS}"
        '';

        interactiveShellInit = ''
          if not set -q tide_cmd_duration_threshold
            source (functions --details _tide_sub_configure)
            _tide_sub_configure --auto --style=Classic --prompt_colors='True color' --classic_prompt_color=Light --show_time='12-hour format' --classic_prompt_separators=Slanted --powerline_prompt_heads=Slanted --powerline_prompt_tails=Slanted --powerline_prompt_style='Two lines, character' --prompt_connection=Disconnected --powerline_right_prompt_frame=No --prompt_spacing=Compact --icons='Many icons' --transient=Yes
          end

          set -U tide_left_prompt_items os context pwd git newline character
          set -U tide_right_prompt_items status cmd_duration jobs direnv bun node python rustc java php pulumi ruby go gcloud kubectl distrobox toolbox terraform aws nix_shell crystal elixir zig time
          set -U tide_context_always_display true
          set -U tide_character_icon '>'
          set -U tide_character_vi_icon_default '>'
          set -U tide_git_icon ""
        '';
      };
    };
}
