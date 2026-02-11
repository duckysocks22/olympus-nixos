{ config, lib, stylix, inputs, pkgs, ... }:

{
  imports = [
    ../../programs/default.nix
    ../../git.nix
    ../../niri/default.nix
    ../../shell.nix
    ../../stylix/stylix.nix
    ../../programs/nixvim.nix
    ../../programs/nixcord.nix
    ../../programs/easyeffects.nix
  ];

  home.username = "foxtrot";
  home.homeDirectory = "/home/foxtrot";

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  home.activation.xdgPortalRestart = config.lib.dag.entryAfter ["writeBoundary"] ''
    run ${pkgs.systemd}/bin/systemctl --user restart xdg-desktop-portal.service
  '';

  # Home-Manager Version
  home.stateVersion = "25.11";
}
