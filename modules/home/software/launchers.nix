{ inputs, self, ... }:
{
  flake.homeModules.launchers =
    {
      inputs,
      osConfig,
      config,
      pkgs,
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
      home.packages = with pkgs; [
        gamemoderun
        prismlauncher
        r2modman
        deadlock-mod-manager
        xivlauncher
        xodus-nexus
        (wrapNoHardened heroic "heroic")
        (wrapNoHardened vacuum-tube "VacuumTube")
        (olympus.override { celesteWrapper = "steam-run"; })
      ];

      programs.mangohud = {
        enable = true;
        enableSessionWide = false;

        settings.preset = 2;
      };

      home.activation.ffxivWinebusSdl = config.lib.dag.entryAfter [ "writeBoundary" ] ''
        reg="${config.home.homeDirectory}/.xlcore/wineprefix/system.reg"
        if [ -f "$reg" ] && ${pkgs.gnugrep}/bin/grep -q '"Enable SDL"=' "$reg"; then
          if ${pkgs.procps}/bin/pgrep -x wineserver > /dev/null; then
            echo "ffxivWinebusSdl: wineserver running, not touching $reg"
          else
            ${pkgs.gnused}/bin/sed -i '/"Enable SDL"=/d' "$reg"
            echo "ffxivWinebusSdl: removed Enable SDL from $reg"
          fi
        fi
      '';
    };
}
