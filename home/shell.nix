{ pkgs, config, ... }:

{
  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      vi = "nvim";
      rebuild = "sudo nixos-rebuild switch --flake ${config.home.homeDirectory}/olympus-nixos";
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

}
