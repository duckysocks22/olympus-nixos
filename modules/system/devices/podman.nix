{ inputs, self, ... }: {
  flake.nixosModules.podman =
    {
      inputs,
      ...
    }:
    {
      virtualisation.podman = {
        enable = true;
        autoPrune.enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
      };

      environment.systemPackages = [
        inputs.compose2nix.packages.x86_64-linux.default
      ];

      users.users.server.extraGroups = [ "podman" ];
    };
}
