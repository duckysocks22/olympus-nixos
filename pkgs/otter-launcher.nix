{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      system,
      ...
    }:
    {
      packages.otter-launcher =
        let
          pkgs = inputs.nixpkgs.legacyPackages.${system};
        in
        pkgs.rustPlatform.buildRustPackage (finalAttrs: {
          pname = "otter-launcher";
          version = "0.8.2";

          src = pkgs.fetchFromGitHub {
            owner = "kuokuo123";
            repo = "otter-launcher";
            tag = "v${finalAttrs.version}";
            hash = "sha256-UfBTQMR/vZ3XQJRX5XwIP+nMcB5qLQo0pBR1jvavmqg=";
          };

          cargoHash = "sha256-SlwIGNNUS64efRBAf3xrg7If6mn/ZGgeeBaNwut30Q4=";

          meta = {
            description = "A hackable cli/tui launcher built for keyboard-centric wm users, featuring vi & emacs keybinds, ansi decoration, etc";
            homepage = "https://github.com/kuokuo123/otter-launcher";
            license = lib.licenses.gpl3;
          };
        });
    };
}
