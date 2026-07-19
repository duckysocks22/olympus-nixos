{ pkgs, inputs, ...}:

let
  gamemoderun = pkgs.writeShellScriptBin "gamemoderun" ''
    exec env \
      PROTON_USE_WAYLAND=1 \
      PROTON_ENABLE_WAYLAND=1 \
      PROTON_ENABLE_HDR=1 \
      PROTON_USE_SDL=1 \
      ${pkgs.gamemode}/bin/gamemoderun "$@"
  '';

  wrapNoHardened = pkg: binName:
    let
      wrapper = pkgs.writeShellScript "${binName}-no-hardened" ''
        exec ${gamemoderun}/bin/gamemoderun \
          ${pkgs.bubblewrap}/bin/bwrap \
            --dev-bind / / \
            --bind /dev/null "$(readlink -f /etc/ld-nix.so.preload)" \
            -- ${pkg}/bin/${binName} "$@"
      '';
    in pkgs.symlinkJoin {
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
  home.packages = [
    gamemoderun
    pkgs.prismlauncher
    inputs.elysia.packages.x86_64-linux.default
    #inputs.agl.packages.x86_64-linux.default
    (wrapNoHardened pkgs.xivlauncher "XIVLauncher.Core")
    (pkgs.olympus.override { celesteWrapper = "steam-run"; })
    pkgs.ludusavi
    pkgs.r2modman
    (wrapNoHardened pkgs.heroic "heroic")
  ];

  programs.mangohud = {
    enable = true;
    enableSessionWide = false;
    settings = {
      preset = 2;
    };
  };
}
