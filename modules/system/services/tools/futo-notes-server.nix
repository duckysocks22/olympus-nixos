{ inputs, ... }:
{
  flake.nixosModules.futo-notes-server =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      systemd.services.futo-notes-server = {
        description = "FUTO Notes live-sync server";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = lib.getExe inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.futo-notes-server;
          User = "futo-notes";
          Group = "futo-notes";
          EnvironmentFile = config.sops.secrets."futo-notes/environment".path;
          WorkingDirectory = "/media/hdd1/services/futo-notes";
          Restart = "on-failure";
        };
      };

      users.users.futo-notes = {
        description = "FUTO Notes Server user";
        isSystemUser = true;
        group = "futo-notes";
        extraGroups = [ "users" ];
        hashedPasswordFile = config.sops.secrets."users/server".path;
      };

      users.groups.futo-notes = { };

      systemd.tmpfiles.rules = [
        "d /media/hdd1/services/futo-notes 0600 futo-notes futo-notes"
      ];
    };
}
