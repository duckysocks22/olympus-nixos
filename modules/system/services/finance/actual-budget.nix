{ inputs, ... }:
{
  flake.nixosModules.actual-budget =
    {
      pkgs,
      util,
      lib,
      ...
    }:
    let
      config = pkgs.writeText "actual-config.json" (
        builtins.toJSON {
          hostname = "0.0.0.0";
          dataDir = "/media/hdd1/services/actual-finance/";
        }
      );

      exec = lib.getExe pkgs.actual-server;
    in
    {
      systemd.services.actual-server = util.functions.mkSimpleService {
        description = "Headless Actual Finance Server";
        ExecStart = "${exec} --config ${config}";
        user = "actual-budget";
      };

      users.users.actual-budget = {
        isSystemUser = true;
        group = "actual-budget";
      };

      users.groups.actual-budget = { };

      systemd.tmpfiles.rules = [
        "d /media/hdd1/services/actual-finance 0600 actual-budget actual-budget"
      ];
    };
}
