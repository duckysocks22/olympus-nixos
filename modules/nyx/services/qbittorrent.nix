{
  util,
  pkgs,
  lib,
  ...
}:
{
  systemd.services.qbittorrent = util.functions.mkSimpleService {
    description = "Headless qBittorrent";
    ExecStart = lib.getExe pkgs.qbittorrent-nox;
    user = "server";
  };

  users.groups.torrent = { };
}
