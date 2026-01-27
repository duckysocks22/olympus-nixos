{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      vi = "nvim";
      rebuild = "sudo nixos-rebuild switch --flake /home/foxtrot/olympus-nixos/";
    };
  };

   xdg.configFile = {
    "fastfetch/config.jsonc".source = ./config/fastfetch.jsonc;
    #"noctalia/settings.json".force = true;
  };

}
