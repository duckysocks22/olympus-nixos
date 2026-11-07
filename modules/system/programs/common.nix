{ inputs, self, ... }:
{
  flake.nixosModules.common =
    {
      config,
      pkgs,
      pkgs-unstable,
      inputs,
      lib,
      ...
    }:
    {
      programs = {
        gnupg.agent.enable = true;
        localsend = {
          enable = true;
          openFirewall = true;
        };
        appimage = {
          enable = true;
          binfmt = true;
          package = pkgs.appimage-run.override {
            extraPkgs = pkgs: [
              pkgs.icu
              pkgs.libxcrypt-legacy
              pkgs.python312
            ];
          };
        };
      };

      environment.systemPackages =
        (with pkgs; [
          unzip
          bubblewrap
          nixfmt-tree
          (writeShellScriptBin "gamescope-run" ''
            gamescope_args=()
            game_cmd=()
            sep_found=false

            for arg in "$@"; do
              if [[ "$arg" == "--" && "$sep_found" == "false" ]]; then
                sep_found=true
              elif [[ "$sep_found" == "true" ]]; then
                game_cmd+=("$arg")
              else
                gamescope_args+=("$arg")
              fi
            done

            # No -- provided: treat everything as the game command
            if [[ "$sep_found" == "false" ]]; then
              game_cmd=("''${gamescope_args[@]}")
              gamescope_args=()
            fi

            # gamescope is a nix binary: keep Steam's runtime paths out of it
            exec env LD_PRELOAD= LD_LIBRARY_PATH= ${pkgs.gamescope}/bin/gamescope \
              "''${gamescope_args[@]}" \
              -- env LD_PRELOAD="$LD_PRELOAD" LD_LIBRARY_PATH="$LD_LIBRARY_PATH" "''${game_cmd[@]}"
          '')
          (writeShellScriptBin "no-hardened" ''
            exec ${pkgs.util-linux}/bin/unshare --mount --user --map-root-user \
              ${pkgs.runtimeShell} -c '
                ${pkgs.util-linux}/bin/mount --bind /dev/null /etc/ld-nix.so.preload
                exec "$@"
              ' no-hardened "$@"
          '')
        ])
        ++ (with inputs.reshade.packages.${pkgs.stdenv.hostPlatform.system}; [
          reshade
          reshade-shaders-full
        ]);

      fonts.packages =
        with pkgs;
        [
          noto-fonts
          noto-fonts-cjk-sans
          noto-fonts-color-emoji
        ]
        ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
    };
}
