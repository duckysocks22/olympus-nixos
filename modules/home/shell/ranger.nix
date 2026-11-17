{ inputs, self, ... }:
{
  flake.homeModules.ranger =
    {
      lib,
      pkgs,
      ...
    }:
    {
      programs.ranger = {
        enable = true;

        plugins = [
          {
            name = "zoxide";
            src = pkgs.fetchFromGitHub {
              owner = "jchook";
              repo = "ranger-zoxide";
              rev = "c64d4aed906487cc8c648f51814682a2c01c21d9";
              hash = "sha256-63EAmdvOxfaBVHKxAp4OyAA+nX3+FPlqFXTvKrmAnYE=";
            };
          }
        ];
      };
    };
}
