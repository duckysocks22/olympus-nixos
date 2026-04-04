{ pkgs, config, lib, ... }:
{
  home.packages = [ pkgs.mktorrent ];
  systemd.user.services = config.lib.functions.mkSimpleService "qbittorrent" (lib.getExe pkgs.qbittorrent-nox);
}
