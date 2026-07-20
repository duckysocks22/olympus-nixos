{ inputs, ... }:
{
  virtualisation.docker = {
    enable = true;
    # Set up resource limits
    daemon.settings = {
      experimental = true;
      default-address-pools = [
        {
          base = "172.30.0.0/16";
          size = 24;
        }
      ];
    };
  };

  environment.systemPackages = [
    inputs.compose2nix.packages.x86_64-linux.default
  ];

  users.users.server.extraGroups = [ "docker" ];
}
