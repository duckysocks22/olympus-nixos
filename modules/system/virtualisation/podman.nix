{ inputs, self, ... }:
{
  flake.nixosModules.podman =
    {
      ...
    }:
    {
      virtualisation.poadman = {
        enable = true;
        dockerCompat = true;
        dockerSocket.enable = true;
        defaultNetwork.settings.dns_enabled = true;
      };

      environment.systemPackages = [
        inputs.compose2nix.packages.x86_64-linux.default
      ];

      users.groups.podman.members = [
        "foxtrot"
        "server"
      ];
    };
}
