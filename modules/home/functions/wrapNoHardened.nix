{ inputs, ... }:
{
  flake.homeModules.wrapNoHardened =
    {
      lib,
      pkgs,
      ...
    }:
    {
      lib.functions.wrapNoHardened =
        pkg: binName:
        {
          execPrefix ? [ ],
        }:
        let
          emptyFile = pkgs.writeText "empty" "";
          wrapper = pkgs.writeShellScript "${binName}-no-hardened" ''
            preload="$(readlink -f /etc/ld-nix.so.preload 2>/dev/null || true)"
            mask=()
            if [ -e "''${preload:-/nonexistent}" ]; then
              mask=(--ro-bind ${emptyFile} "$preload")
            fi
            exec ${pkgs.bubblewrap}/bin/bwrap \
              --dev-bind / / \
              "''${mask[@]}" \
              -- ${lib.escapeShellArgs execPrefix} ${pkg}/bin/${binName} "$@"
          '';
        in
        pkgs.symlinkJoin {
          name = "${pkg.pname or pkg.name}-no-hardened";
          paths = [ pkg ];
          postBuild = ''
            rm -f "$out/bin/${binName}"
            cp ${wrapper} "$out/bin/${binName}"
          '';
        };
    };
}
