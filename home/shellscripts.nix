{ pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellScriptBin "mountiso" ''
      iso="$1"
      mountpoint="''${2:-}"

      function unmount(){
        if mountpoint "$1" > /dev/null; then
          sudo umount -l "$1"
          rmdir --ignore-fail-on-non-empty "$1"
          exit 0
        else
          echo "Path $1 does not exist or is not a mountpoint."
          exit 1
        fi
      }

      if test -z "$mountpoint"; then
        mountpoint=./iso
      fi

      if [[ "$1" == "-l" ]]; then
        unmount "$mountpoint"
      fi

      mkdir -p "$mountpoint"
      sudo mount -o loop "$iso" "$mountpoint" \
        || rmdir --ignore-fail-on-non-empty "$mountpoint"
    '')
  ];
}
