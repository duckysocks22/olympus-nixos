{ inputs, self, ... }:
{
  flake.homeModules.adwaita-for-steam =
    { pkgs, lib, ... }:
    let
      adwaita-src = pkgs.fetchFromGitHub {
        owner = "tkashkin";
        repo = "Adwaita-for-Steam";
        rev = "4.4";
        hash = "sha256-wH0z2LZ94j5ErRI40f9IRBJXJ6yuL+NLgjmj9G8odxU=";
      };
      adwaita-for-steam = adwaita-src;
      install-adwaita-steam = pkgs.writeShellScript "install-adwaita-steam" ''
        target="''${HOME}/.local/share/Steam/steamui/adwaita"
        if [ -d "$target" ]; then
          chmod -Rf u+w "$target" 2>/dev/null || true
          rm -rf "$target" 2>/dev/null || true
        fi
        workdir=$(mktemp -d)
        trap 'rm -rf "$workdir"' EXIT
        cp -a ${adwaita-for-steam}/. "$workdir/"
        chmod -Rf u+w "$workdir"
        cd "$workdir"
        exec ${pkgs.python3}/bin/python3 install.py \
          --target default \
          --color-theme gruvbox \
          --color-scheme auto \
          --windowcontrols-layout gnome 
      '';
    in
    {
      systemd.user.services.adwaita-steam = {
        Unit = {
          Description = "Apply Adwaita-for-Steam skin";
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${install-adwaita-steam}";
        };
        Install.WantedBy = [ "default.target" ];
      };

      systemd.user.timers.adwaita-steam = {
        Timer = {
          OnCalendar = "daily";
          Persistent = true;
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };
}
