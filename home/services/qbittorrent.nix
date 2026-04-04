{ inputs, ... }:
{
  flake.homeModules.qbittorrent = { pkgs, lib, config, ... }: {
    home.packages = [ pkgs.mktorrent ];
    systemd.user.services = config.lib.functions.mkSimpleService "qbittorrent" (lib.getExe pkgs.qbittorrent-nox);
  };
}
