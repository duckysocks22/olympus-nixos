{ inputs, self, ... }: {
  flake.nixosModules.mouseModifiers = { pkgs, ... }: {
    services.udev.extraRules = ''
      KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
    '';

    systemd.services.mouse-modifiers = {
      description = "Remap mouse side buttons to Ctrl/Shift via evsieve";
      after = [ "systemd-udevd.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = "foxtrot";
        SupplementaryGroups = [ "input" ];
        Restart = "always";
        RestartSec = "2";
      };
      script = ''
        shopt -s nullglob
        mice=(/dev/input/by-id/*-event-mouse)
        if [ ''${#mice[@]} -eq 0 ]; then
          echo "mouse-modifiers: no mouse event devices found" >&2
          exit 1
        fi
        exec ${pkgs.evsieve}/bin/evsieve --input "''${mice[@]}" grab persist=reopen \
          --map btn:side key:leftshift \
          --map btn:extra key:leftctrl \
          --output name=evsieve-mouse
      '';
    };
  };
}
