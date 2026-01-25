{ config, lib, ... }:

{
  imports = [
    ../../programs/default.nix
    ../../git.nix
    ../../niri/default.nix
    ../../shell.nix
  ];

  home.username = "foxtrot";
  home.homeDirectory = "/home/foxtrot";

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # Home-Manager Version
  home.stateVersion = "25.11";
}
