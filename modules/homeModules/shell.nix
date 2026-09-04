{ inputs, self, ... }:
{
  flake.homeModules.shell = { pkgs, config, inputs, pkgs-unstable, ... }: let 
    attic-client = pkgs-unstable.attic-client;
    gray = builtins.fromJSON ''"\u001b[90m"'';
  in {
    imports = [ 
      self.homeModules.git
      inputs.nix-index-database.homeModules.default
    ];

    home.packages =
      (with pkgs; [
        ripgrep
        tmux
        elmPackages.nodejs
        pkg2zip
        jp2a
        shellcheck
        dust
        rclone
        attic-client
        gh
        btop
        cdrdao
      ]) ++ (with inputs.luxxy-pkgs.packages.${pkgs.stdenv.hostPlatform.system}; [
        unscene
        mountiso
      ]);

    programs = {
      ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings."*" = {
          ForwardAgent = false;
          AddKeysToAgent = "yes";
          Compression = false;
          ServerAliveInterval = 0;
          ServerAliveCountMax = 3;
          HashKnownHosts = false;
          UserKnownHostsFile = "~/.ssh/known_hosts";
          ControlMaster = "no";
          ControlPath = "~/.ssh/master-%r@%n:%p";
          ControlPersist = "no";
        };
      };
      zsh = {
        enable = true;
        syntaxHighlighting.enable = true;

        shellAliases = {
          vi = "nvim";
          #rebuild = "sudo nixos-rebuild switch -L --flake ${config.home.homeDirectory}/olympus-nixos";
          rebuild = "nh os switch";
          par = ''
            cd ${config.home.homeDirectory}/olympus-nixos
            git pull
            nh os switch
            attic push main /run/current-system'';
          #cleanup = "sudo nix-collect-garbage --delete-old";
          cleanup = "nh clean all";
          hb = "HandBrakeCLI";
          buildiso = ''
            cd ~/olympus-nixos
            nix build -L .#nixosConfigurations.olympus-iso.config.system.build.isoImage
          '';
          weather = ''curl "wttr.in/?u"'';
          ai-commit = ''git commit --trailer "Co-Authored-By: GLM-5.3-Flash <noreply@z.ai>"'';
          cachestore = "attic push --ignore-upstream-cache-filter main $(ls -d /nix/store/*/ | grep -v fake_nixpkgs)";
          cachesys = "attic push main /run/current-system";
          cp = "rsync --progress --stats";
        };

        initContent = ''
          function encode() {
            if [[ "$1" == "-h" || "$1" == "--help" ]]; then
              echo "Usage: encode [INPUT] [OUTPUT]"
              echo "Used to encode media via HandBrake with set parameters."
              return 0
            fi

            HandBrakeCLI --input "$1" --output "$2" --encoder x265 -x pools=6 --all-audio --all-subtitles --aencoder opus
          };

          function bulkencode() {
            if [[ "$1" == "-h" || "$1" == "--help" ]]; then
              echo "Usage: bulkencode [INPUT_DIR] [OUTPUT_DIR]"
              echo "Used to bulk encode a directory of media via HandBrake with set parameters."
              return 0
            fi
            cd $1 
            for f in *.mkv; do
              HandBrakeCLI --input "$f" --output "$2/$f" --encoder x265 -x pools=6 --all-audio --all-subtitles --aencoder opus
            done
          };

          function firefoxid() {
            if [[ "$1" == "-h" || "$1" == "--help" ]]; then
              echo "Usage: firefoxid [EXTENSION_NAME] or [EXTENSION_URL]"
              echo "Used to find the UUID of a Firefox Extension"
            fi

            nix run github:tupakkatapa/mozid -- "$1"
          };

          function securewipe() {
            if [[ "$1" == "-h" || "$1" == "--help" ]]; then
              echo "Usage: securewipe [DISK]"
              echo "Used to zero out and randomize data on drive to securely wipe all data."
            fi

            sudo dd if=/dev/zero of="$1" bs=512 status="progress"
          }

          function psxrip() {
            if [[ "$1" == "-h" || "$1" == "--help" ]]; then
              echo "Usage: psxrip [GAME_NAME]"
              echo "Rips PSX game to current directory."
            fi

            cdrdao read-cd --read-raw --read-subchan rw_raw --datafile $1.bin --device /dev/sr0 --driver generic-mmc-raw $1.toc
          }

          export FZF_DEFAULT_OPS="${config.home.sessionVariables.FZF_DEFAULT_OPTS}"
          zstyle ':fzf-tab:*' use-fzf-default-opts yes
        '';

        oh-my-zsh = {
          enable = true;
          theme = "candy";
        };

        plugins = [
          {
            name = pkgs.zsh-fzf-tab.pname;
            src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
            file = "fzf-tab.plugin.zsh";
          }
          {
            name = pkgs.zsh-autosuggestions.pname;
            src = pkgs.zsh-autosuggestions.src;
            file = "zsh-autosuggestions.plugin.zsh";
          }
        ];
      };

      fastfetch = {
        enable = true;
        settings = {
          "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
          logo = {
            type = "file";
            source = "~/.config/fastfetch/ascii.txt";
            color = { "1" = "#B84F8E"; "2" = "#EB8034"; };
            height = 15;
            width = 8;
            padding = { top = 5; left = 3; };
          };
          modules = [
            "break"
            { type = "custom"; format = "${gray}┌──────────────────────Hardware──────────────────────┐"; }
            { type = "host";    key = " PC";  keyColor = "green"; }
            { type = "cpu";     key = "│ ├";  keyColor = "green"; }
            { type = "gpu";     key = "│ ├󰍛";  keyColor = "green"; }
            { type = "memory";  key = "│ ├󰍛";  keyColor = "green"; }
            { type = "disk";    key = "└ └"; keyColor = "green"; }
            { type = "custom";  format = "${gray}└────────────────────────────────────────────────────┘"; }
            "break"
            { type = "custom";  format = "${gray}┌──────────────────────Software──────────────────────┐"; }
            { type = "os";      key = " OS";  keyColor = "yellow"; }
            { type = "kernel";  key = "│ ├";  keyColor = "yellow"; }
            { type = "bios";    key = "│ ├";  keyColor = "yellow"; }
            { type = "packages"; key = "│ ├󰏖"; keyColor = "yellow"; }
            { type = "shell";   key = "└ └"; keyColor = "yellow"; }
            "break"
            { type = "de";       key = " DE";   keyColor = "blue"; }
            { type = "lm";       key = "│ ├";   keyColor = "blue"; }
            { type = "wm";       key = "│ ├";   keyColor = "blue"; }
            { type = "wmtheme";  key = "│ ├󰉼";   keyColor = "blue"; }
            { type = "terminal"; key = "└ └";   keyColor = "blue"; }
            { type = "custom";   format = "${gray}└────────────────────────────────────────────────────┘"; }
            "break"
            { type = "custom"; format = "${gray}┌────────────────────Uptime / Age / DT────────────────────┐"; }
            {
              type = "command";
              key = "  OS Age ";
              keyColor = "magenta";
              text = "birth_install=$(stat -c %W /persistent); current=$(date +%s); time_progression=$((current - birth_install)); days_difference=$((time_progression / 86400)); echo $days_difference days";
            }
            { type = "uptime";   key = "  Uptime ";   keyColor = "magenta"; }
            { type = "datetime"; key = "  DateTime "; keyColor = "magenta"; }
            { type = "custom";   format = "${gray}└─────────────────────────────────────────────────────────┘"; }
            { type = "colors";   paddingLeft = 2; symbol = "circle"; }
          ];
        };
      };

      fzf = {
        enable = true;
        enableZshIntegration = true;
        defaultOptions = [
          "--ansi"
          "--bind=tab:down,btab:up,change:top,ctrl-space:toggle"
          "--border=rounded"
          "--cycle"
          "--ignore-case"
          "--info=hidden"
          "--layout=reverse"
          "--multi"
          "--tiebreak=begin"
        ];
      };
      
      ranger.enable = true;

      direnv = {
        enable = true;
        enableZshIntegration = true;
      };

      nix-index-database.comma.enable = true;
    };

    dconf.settings = {
      "org/virt-manager/virt-manager/connections" = {
        autoconnect = [ "qemu:///system" ];
        uris = [ "qemu:///system" ];
      };
    };

    xdg.configFile"fastfetch/ascii.txst".source = ../../assets/ascii.txt
  };

  flake.homeModules.git = { pkgs, ... }: {
    programs.git = {
      enable = true;
      ignores = [
        "result"
        ".direnv"
        ".claude"
      ];
      settings = {
        push = { autoSetupRemote = true; };
        pull = { rebase = false; };
        init = { defaultBranch = "main"; };
        commit = { gpgSign = true; };
        user = { name = "foxtrottt"; email = "code@olympus.moe"; };
        credential = { "https://dawn.wine" = { helper = "oauth"; }; helper = "libsecret"; };
        signing = { format = "ssh"; key = "~/.ssh/id_ed25519.pub"; signByDefault };
      };
    };
  };
}
