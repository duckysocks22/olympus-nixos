{ inputs, self, ... }:
{
  flake.homeModules.ssh =
    {
      ...
    }:
    {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings = {
          "*.nyx-nixos.olympus.netbird" = {
            Compression = true;
          };

          "192.168.10.*" = {
            Compression = true;
          };

          "*" = {
            ForwardAgent = false;
            AddKeysToAgent = "yes";
            Compression = false;
            ServerAliveInterval = 0;
            ServerAliveCountMax = 3;
            HashKnownHosts = false;
            UserKnownHostsFile = "~/.ssh/known_hosts";
            ControlMaster = "no";
            ControlPath = "~/.ssh/master-%r@%n:%p";
            ControlPersist = "no";
          };
        };
      };
    };
}
