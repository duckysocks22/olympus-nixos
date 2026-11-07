{ inputs, self, ... }:
{
  flake.homeModules.launchers =
    {
      pkgs,
      inputs,
      osConfig,
      lib,
      ...
    }:
    let
      gamemoderun = pkgs.writeShellScriptBin "gamemoderun" ''
        exec env \
          ${pkgs.gamemode}/bin/gamemoderun "$@"
      '';

      wrapNoHardened =
        pkg: binName:
        let
          wrapper = pkgs.writeShellScript "${binName}-no-hardened" ''
            unset LD_LIBRARY_PATH
            unset LD_PRELOAD
            exec ${gamemoderun}/bin/gamemoderun \
              ${pkgs.bubblewrap}/bin/bwrap \
                --dev-bind / / \
                --bind /dev/null "$(readlink -f /etc/ld-nix.so.preload)" \
                -- ${pkg}/bin/${binName} "$@"
          '';
        in
        pkgs.symlinkJoin {
          name = "${pkg.pname or pkg.name}-no-hardened";
          paths = [ pkg ];
          postBuild = ''
            rm -f "$out/bin/${binName}"
            cp ${wrapper} "$out/bin/${binName}"
            chmod +x "$out/bin/${binName}"
          '';
        };
    in
    {
      imports = lib.optionals (!(osConfig ? jovian)) [ inputs.self.homeModules.adwaita-for-steam ];

      home.packages = [
        gamemoderun
        pkgs.prismlauncher
        inputs.elysia.packages.x86_64-linux.default
        (wrapNoHardened pkgs.heroic "heroic")
        (wrapNoHardened pkgs.vacuum-tube "VacuumTube")
        (pkgs.olympus.override { celesteWrapper = "steam-run"; })
        pkgs.r2modman
        pkgs.deadlock-mod-manager
        pkgs.xivlauncher
        inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.xodus-nexus
      ];

      programs.mangohud = {
        enable = true;
        enableSessionWide = false;
        settings = {
          preset = 2;
        };
      };
    };
}
