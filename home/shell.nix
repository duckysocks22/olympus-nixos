{ pkgs, config, inputs, ... }:
let
  pkg2zip = pkgs.callPackage ../modules/packages/pkg2zip.nix { };
in
{
  home.packages = (with pkgs; [
    ripgrep
    tmux
    nodePackages.npm
    inputs.px7-radio-git.packages.${pkgs.system}.default
    pkg2zip
  ]) ++ (with inputs.luxxy-pkgs.packages.${pkgs.system}; [
    unscene
    mountiso
  ]);

  imports = [ inputs.nix-index-database.homeModules.default ];
  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      vi = "nvim";
      rebuild = "sudo nixos-rebuild switch --flake ${config.home.homeDirectory}/olympus-nixos";
      par = ''
      cd ${config.home.homeDirectory}/olympus-nixos
      git pull
      sudo nixos-rebuild switch --flake ${config.home.homeDirectory}/olympus-nixos'';
      cleanup = "sudo nix-collect-garbage --delete-old";
      hb = "HandBrakeCLI";
      buildiso = ''
      cd ~/olympus-nixos
      nix build .#nixosConfigurations.olympus-iso.config.system.build.isoImage -L
      '';
    };

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

    initContent = ''
    export FZF_DEFAULT_OPTS="${config.home.sessionVariables.FZF_DEFAULT_OPTS}"
zstyle ':fzf-tab:*' use-fzf-default-opts yes
    '';
  };

   xdg.configFile = {
    "fastfetch/config.jsonc".source = ./config/fastfetch.jsonc;
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
}
