{ inputs, ... }:
{
  flake.nixosModules.jovianPlasma =
    {
      ...
    }:
    let
      # Every session-bus activated wallet daemon aborts on Qt platform init when the
      # session has no display (gamescope unsets DISPLAY), killing the daemon mid-request.
      # Activate them through a wrapper that only falls back to offscreen when nothing
      # can render, and own the activation files so the packaged raw Exec= never wins.
      walletDaemon =
        name: binary:
        pkgs.writeShellScript "${name}-activate" ''
          if [ -z "''${DISPLAY:-}" ]; then
            export QT_QPA_PLATFORM=offscreen
          fi
          exec ${pkgs.kdePackages.kwallet}/bin/${binary}
        '';
      ksecretdActivate = walletDaemon "ksecretd" "ksecretd";
      kwalletdActivate = walletDaemon "kwalletd" "kwalletd6";
      walletService =
        name: exec:
        lib.hiPrio (
          pkgs.writeTextDir "share/dbus-1/services/${name}.service" ''
            [D-BUS Service]
            Name=${name}
            Exec=${exec}
          ''
        );

      # ksecretd only unlocks a passwordless collection on a retried request and answers the
      # first one with an org.freedesktop.Secret.Prompt it cannot complete (no Prompt() and
      # no Completed), so clients that ask once see the wallet as locked. Drive the retry.
      ensureUnlocked = pkgs.writeShellScript "kwallet-ensure-unlocked" ''
        collection=/org/freedesktop/secrets/collection/default
        for _ in $(seq 1 10); do
          if [ "$(busctl --user get-property org.freedesktop.secrets "$collection" \
            org.freedesktop.Secret.Collection Locked 2>/dev/null)" = "b false" ]; then
            exit 0
          fi
          busctl --user call org.freedesktop.secrets /org/freedesktop/secrets \
            org.freedesktop.Secret.Service Unlock ao 1 "$collection" >/dev/null 2>&1
          sleep 1
        done
        echo "kwallet: default collection stayed locked" >&2
        exit 1
      '';
    in
    {
      services = {
        desktopManager.plasma6.enable = true;
        xserver.enable = true;

        # KWallet is managing secrets on Jovian-NixOS systems
        gnome.gnome-keyring.enable = lib.mkForce false;
      };

      environment.plasma6.excludePackages = with pkgs.kdePackages; [
        plasma-browser-integration
        konsole
        elisa
      ];

      security.pam.services.niri = {
        enableGnomeKeyring = lib.mkForce false;
        kwallet.enable = true;
      };

      # Auto-unlock KWallet in gamescope.
      systemd.user.services.kwalletd6 = {
        description = "KWallet daemon (answers ksecretd unlock prompts)";

        wantedBy = [
          "default.target"
          "gamescope-session.target"
        ];

        serviceConfig = {
          ExecStart = kwalletdActivate;
          Restart = "on-falure";
          RestartSec = 5;
        };
      };

      systemd.user.services.kwallet-unlock = {
        description = "Unlock the passwordless default wallet";
        wantedBy = [
          "default.target"
          "gamescope-session.target"
        ];
        after = [ "kwalletd6.service" ];
        unitConfig.ConditionPathExists = "%h/.local/share/kwalletd/default.kwl";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = ensureUnlocked;
        };
      };

      environment.systemPackages = [
        (walletService "org.freedesktop.secrets" ksecretdActivate)
        (walletService "org.kde.secretservicecompat" ksecretdActivate)
        (walletService "org.freedesktop.impl.portal.desktop.kwallet" ksecretdActivate)
        (walletService "org.kde.kwalletd6" kwalletdActivate)
        (walletService "org.kde.kwalletd5" kwalletdActivate)
      ];

      # Stops 'drkonqi-coredump-processor' from flooding logs with crash loop
      systemd.services."drkonqi-coredump-processor@".wantedBy = lib.mkForce [ ];
    };
}
