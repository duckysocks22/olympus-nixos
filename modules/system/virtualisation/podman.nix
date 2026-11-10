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
    };
}
