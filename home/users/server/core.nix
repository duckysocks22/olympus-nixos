{
  config,
  lib,
  stylix,
  inputs,
  ...
}:

{
  imports = [
    ../../git.nix
    ../../shell.nix
    ../../programs/common.nix
    ../../programs/claude-code.nix
    ../../programs/nixvim.nix
    ../../programs/browsers.nix
    ../../functions.nix
    ../../services/qbittorrent.nix
    ../../stylix/stylix.nix
  ];

  home.username = "server";
  home.homeDirectory = "/home/server";

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # Home-Manager Version
  home.stateVersion = "26.05";
}
