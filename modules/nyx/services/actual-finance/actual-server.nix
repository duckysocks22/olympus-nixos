{ pkgs, util, lib, ... }:
let
  exec = lib.getExe pkgs.actual-server;
  configPath = ./config.json;
in
{
  systemd.services.actual-server = util.functions.mkSimpleService {
    description = "Headless Actual Finances Server";
    ExecStart = "${exec} --config ${configPath}";
    user = "root";
  };
}
