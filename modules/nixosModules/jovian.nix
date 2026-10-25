{ inputs, self, ... }: {
  flake.nixosModules.jovian =
    {
      config,
      pkgs,
      lib,
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
      imports = [ inputs.jovian.nixosModules.default ];

      jovian = {
        steam = {
          enable = true;
          autoStart = true;
          desktopSession = "plasma";
          user = "deck";
          environment.STEAM_EXTRA_COMPAT_TOOLS_PATHS =
            lib.makeSearchPathOutput "steamcompattool" ""
              config.programs.steam.extraCompatPackages;
        };
        devices.steamdeck = lib.mkIf (config.networking.hostName == "dionysus-nixos") {
          enable = true;
          autoUpdate = true;
        };
        devices.steammachine = lib.mkIf (config.networking.hostName == "ariadne-nixos") {
          enable = true;
          autoUpdate = true;
        };
        decky-loader = {
          enable = true;
          user = "deck";
          package = pkgs.jovianPackages.decky-loader-prerelease;
        };
      };

      systemd.services.steam-cef-debug = lib.mkIf config.jovian.decky-loader.enable {
        description = "Create Steam CEF debugging file";
        serviceConfig = {
          Type = "oneshot";
          User = config.jovian.steam.user;
          ExecStart = "/bin/sh -c '[ -e ~/.steam/steam ] && { [ ! -f ~/.steam/steam/.cef-enable-remote-debugging ] && touch ~/.steam/steam/.cef-enable-remote-debugging || true; }; true'";
        };
        wantedBy = [ "multi-user.target" ];
      };

      systemd.tmpfiles.rules = lib.mkIf config.jovian.decky-loader.enable [
        "d ${config.jovian.decky-loader.stateDir}/plugins 0755 ${config.jovian.decky-loader.user} - - -"
        "L+ ${config.jovian.decky-loader.stateDir}/plugins/decky-lsfg-vk - ${config.jovian.decky-loader.user} - - ${
          inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.decky-lsfg-vk
        }/Decky LSFG-VK"
      ];

      services = {
        desktopManager.plasma6.enable = true;
        xserver.enable = true;

        # KWallet (shipped with Plasma above) is the only Secret Service provider here.
        # GNOME Keyring would otherwise claim org.freedesktop.secrets in every session
        # while never having a default collection, so apps report "the keyring is
        # running, but it has no default wallet".
        gnome.gnome-keyring.enable = lib.mkForce false;
      };

      security.pam.services.niri = {
        enableGnomeKeyring = lib.mkForce false;
        kwallet.enable = true;
      };

      # ksecretd provides org.freedesktop.secrets but nothing ships an activation file for
      # it, so libsecret clients find no owner. It used to be pre-started headless instead,
      # so a display-less instance owned the wallet names in desktop sessions too, where
      # its password prompts can never be shown - that wedged kwalletd6 and froze the wallet
      # manager. Activate it on demand, going headless only when the session has no display.
      environment.systemPackages = [
        (walletService "org.freedesktop.secrets" ksecretdActivate)
        (walletService "org.kde.secretservicecompat" ksecretdActivate)
        (walletService "org.freedesktop.impl.portal.desktop.kwallet" ksecretdActivate)
        (walletService "org.kde.kwalletd6" kwalletdActivate)
        (walletService "org.kde.kwalletd5" kwalletdActivate)
      ];

      systemd.services."drkonqi-coredump-processor@".wantedBy = lib.mkForce [ ];

      systemd.user.services.kwalletd6 = {
        description = "KWallet daemon (answers ksecretd unlock prompts)";
        wantedBy = [
          "default.target"
          "gamescope-session.target"
        ];
        serviceConfig = {
          ExecStart = kwalletdActivate;
          Restart = "on-failure";
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

      environment.plasma6.excludePackages = with pkgs.kdePackages; [
        plasma-browser-integration
        konsole
        elisa
      ];

      programs.steam = {
        enable = true;
      };

      boot.plymouth = {
        enable = true;
        theme = lib.mkForce "steamos";
        themePackages = [
          inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.steamos-plymouth
        ];
      };

      boot.loader.timeout = 1;

      boot.loader.limine.extraConfig = ''
        quiet: yes
      '';
    };
}
