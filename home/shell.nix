{ pkgs, config, inputs, pkgs-unstable, ... }:
let
  pkg2zip = pkgs.callPackage ../modules/packages/pkg2zip.nix { };
  carddump = pkgs.callPackage ../modules/scripts/carddump.nix { };
  attic-client = pkgs-unstable.attic-client;
in
{
  home.packages = (with pkgs; [
    ripgrep
    tmux
    elmPackages.nodejs
    inputs.px7-radio-git.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkg2zip
    carddump
    jp2a # Image to ASCII Converter
    shellcheck # Shell script checker
    dust # Tree-formatted disk analyzer
    rclone
    attic-client
    gh
    btop
  ]) ++ (with inputs.luxxy-pkgs.packages.${pkgs.stdenv.hostPlatform.system}; [
    unscene
    mountiso
  ]);

  imports = [ 
    inputs.nix-index-database.homeModules.default
  ];
  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      vi = "nvim";
      rebuild = "sudo nixos-rebuild switch -L --flake ${config.home.homeDirectory}/olympus-nixos |& tee /tmp/rebuild.txt";
      par = ''
      cd ${config.home.homeDirectory}/olympus-nixos
      git pull
      sudo nixos-rebuild switch --flake ${config.home.homeDirectory}/olympus-nixos
      attic push main /run/current-system'';
      cleanup = "sudo nix-collect-garbage --delete-old";
      hb = "HandBrakeCLI";
      buildiso = ''
      cd ~/olympus-nixos
      nix build -L .#nixosConfigurations.olympus-iso.config.system.build.isoImage
      '';
      weather = ''curl "wttr.in/?u"'';
      cachestore = ''attic push --ignore-upstream-cache-filter main $(ls -d /nix/store/*/ | grep -v fake_nixpkgs)'';
      cachesys = ''attic push main /run/current-system'';
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

   xdg.configFile = {
    "fastfetch/config.jsonc".source = ./config/fastfetch.jsonc;
    "fastfetch/ascii.txt".source = ./config/ascii.txt;
    #"noctalia/settings.json".force = true;
  };

  #programs.btop.enable = true;

  programs.fzf = {
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

  stylix.targets.fzf.enable = true;

  programs.ranger = {
    enable = true;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.nix-index-database.comma.enable = true;

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };

}
