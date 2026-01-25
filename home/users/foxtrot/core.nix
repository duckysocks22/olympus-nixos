{ config, pkgs, ... }:

{

  imports = [
    ../../programs/default.nix
    ../../git.nix
    ../../niri/default.nix
  ];

  home.username = "foxtrot";
  home.homeDirectory = "/home/foxtrot";

  programs.bash = {
    enable = true;
    enableCompletion = true;

    bashrcExtra = ''
      export PATH="$PATH:$HOME/bin:$HOME/.local/bin:$HOME/go/bin"
    '';

    shellAliases = {
      vi = "nvim";
      rebuild = "sudo nixos-rebuild switch --flake /home/foxtrot/olympus-nixos/";
    };
   };

   # Nicely reload system units when changing configs
   systemd.user.startServices = "sd-switch";

   # Home-Manager Version
   home.stateVersion = "25.11";
}
