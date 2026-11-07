{ inputs, self, ... }:
{
  flake.homeModules.common =
    {
      config,
      pkgs,
      ...
    }:
    {
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

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "x-scheme-handler/unityhub" = "unityhub.desktop";
        };
      };

      xdg.configFile."mimeapps.list".force = false;

      home.packages =
        with pkgs;
        [
          fastfetch
          kdePackages.dolphin
          unrar
          p7zip
          filezilla
          lunatask
          kdePackages.kate
          kdePackages.okular
          simple-scan
        ]
        ++ [ inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.futo-notes ];

      programs.kitty = {
        enable = true;
        settings = {
          confirm_os_window_close = 0;
        };
      };
    };
}
