{ inputs, ... }:
{
  flake.nixosModules.appimage-run =
    {
      pkgs,
      ...
    }:
    {
      programs.appimage = {
        enable = true;
        binfmt = true;

        package = pkgs.appimage-run.override {
          extraPkgs =
            pkgs: with pkgs; [
              icu
              libxcrypt-legacy
              python312
            ];
        };
      };
    };
}
