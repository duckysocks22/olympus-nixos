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
    in
    {
      home.packages =
        with pkgs;
        [
          gamemoderun
          prismlauncher
          r2modman
          xivlauncher
          xodus-nexus
          (config.lib.functions.wrapNoHardened heroic "heroic" {
            execPrefix = [ "${gamemoderun}/bin/gamemoderun" ];
          })
          (config.lib.functions.wrapNoHardened vacuum-tube "VacuumTube" {
            execPrefix = [ "${gamemoderun}/bin/gamemoderun" ];
          })
          (olympus.override { celesteWrapper = "steam-run"; })
        ]
        # nixpkgs-unstable's cargo hook forces system AWS-LC, which
        # deadlock-mod-manager does not provide; keep it off the deck user.
        ++ lib.optionals (config.home.username != "deck") [ deadlock-mod-manager ];

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
