{ inputs, self, ... }:
{
  flake.homeModules.direnv =
    {
      ...
    }:
    {
      programs.direnv = {
        enable = true;
        enableFishIntegration = true;
        nix-direnv.enable = true;

        config = {
          whitelist = {
            prefix = [ "~/olympus-nixos" ];
          };
        };
      };
    };
}
