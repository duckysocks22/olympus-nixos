{ inputs, self, ... }: {
  flake.nixosModules.defaultSops =
    {
      inputs,
      config,
      pkgs,
      ...
    }:
    let
      # iwd (via ell) cannot parse the p11-kit-format CA bundle NixOS installs:
      # any "-----BEGIN TRUSTED CERTIFICATE-----" block aborts the whole load.
      # Extract only the plain X.509 certificates into a standalone PEM file.
      iwdCaBundle = pkgs.runCommand "iwd-ca-certificates.pem" { } ''
        awk '/^-----BEGIN CERTIFICATE-----$/,/^-----END CERTIFICATE-----$/' \
          ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt > $out
      '';
      common = ../../secrets/common.yaml;
    in
    {
      imports = [
        inputs.sops-nix.nixosModules.sops
      ];

      sops.defaultSopsFile = ../../secrets/${config.networking.hostName}.yaml;
      sops.defaultSopsFormat = "yaml";
      sops.useSystemdActivation = true;

      sops.age.keyFile = "${config.users.users.foxtrot.home}/.config/sops/age/keys.txt";

      sops.secrets."samba/local" = {
        sopsFile = common;
        mode = "0440";
        owner = config.users.users.foxtrot.name;
        group = config.users.users.foxtrot.group;
      };

      sops.secrets."users/foxtrot" = {
        neededForUsers = true;
      };

      sops.secrets."networks/work/network".sopsFile = common;
      sops.secrets."networks/work/user".sopsFile = common;
      sops.secrets."networks/work/pass".sopsFile = common;
      sops.secrets."networks/work/domain".sopsFile = common;

      sops.secrets."networks/bazinga/pass".sopsFile = common;

      sops.secrets."attic/client-config" = {
        owner = config.users.users.foxtrot.name;
        sopsFile = common;
      };

      systemd.services.iwd-hidden-profile = {
        description = "Dynamically generate IWD profile for Work Network";
        wantedBy = [ "multi-user.target" ];
        before = [
          "iwd.service"
          "NetworkManager.service"
        ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };

        script = ''
                SSID=$(cat ${config.sops.secrets."networks/work/network".path})
                USER=$(cat ${config.sops.secrets."networks/work/user".path})
                PASS=$(cat ${config.sops.secrets."networks/work/pass".path})
                DOMAIN=$(cat ${config.sops.secrets."networks/work/domain".path})

                TARGET_FILE="/var/lib/iwd/$SSID.8021x"

                cat <<EOF > "$TARGET_FILE"
          [Security]
          EAP-Method=PEAP
          EAP-Identity=$USER
          EAP-PEAP-CACert=${iwdCaBundle}
          EAP-PEAP-ServerDomainMask=*.$DOMAIN
          EAP-PEAP-Phase2-Method=MSCHAPV2
          EAP-PEAP-Phase2-Identity=$USER
          EAP-PEAP-Phase2-Password=$PASS

          [Settings]
          AutoConnect=true
          ScanForHiddenNetwork=true
          EOF

                chown root:root "$TARGET_FILE"
                chmod 0600 "$TARGET_FILE"
        '';
      };
    };

  flake.nixosModules.aetherSops = { inputs, config, ... }:
    let
      serverShared = ../../secrets/server-shared.yaml;
      common = ../../secrets/common.yaml;
    in
    {
      imports = [
        inputs.sops-nix.nixosModules.sops
      ];

      sops.defaultSopsFile = ../../secrets/aether-nixos.yaml;
    sops.defaultSopsFormat = "yaml";
    sops.useSystemdActivation = true;

    sops.age.keyFile = "${config.users.users.server.home}/.config/sops/age/keys.txt";

    sops.secrets."users/server" = {
      neededForUsers = true;
      sopsFile = serverShared;
    };

    sops.secrets."caddy/environment".sopsFile = serverShared;
    sops.secrets."caddy/ca-cert" = {
      owner = "caddy";
    };

    sops.secrets."attic/client-config" = {
      owner = config.users.users.server.name;
      sopsFile = common;
    };
  };

  flake.nixosModules.serverSops = { inputs, config, ... }:
    let
      serverShared = ../../secrets/server-shared.yaml;
      common = ../../secrets/common.yaml;
    in
    {
    imports = [
      inputs.sops-nix.nixosModules.sops
    ];

    sops.defaultSopsFile = ../../secrets/nyx-nixos.yaml;
    sops.defaultSopsFormat = "yaml";
    sops.useSystemdActivation = true;

    sops.age.keyFile = "${config.users.users.server.home}/.config/sops/age/keys.txt";

    sops.secrets."atuin/env" = { };
    sops.secrets."atuin/ai-env" = { };

    sops.secrets."homepage/secrets" = { };

    sops.secrets."llama-cpp/api-key" = {
      mode = "0440";
      owner = config.users.users.server.name;
      group = config.users.users.server.group;
    };
    sops.secrets."finance-summary/env" = { };

    sops.secrets."samba-nyx/socks" = { };
    sops.secrets."samba-nyx/serena" = { };
    sops.secrets."samba-nyx/zia" = { };
    sops.secrets."users/server" = {
      sopsFile = serverShared;
      neededForUsers = true;
    };
    sops.secrets."users/foxtrot" = { };
    sops.secrets."caddy/environment" = {
      sopsFile = serverShared;
    };
    sops.secrets."adguardhome/environment" = { };
    sops.secrets."attic/server-token" = { };
    sops.secrets."attic/client-config" = {
      owner = config.users.users.server.name;
      sopsFile = common;
    };
    sops.secrets."forgejo-runner/environment" = { };
    sops.secrets."navidrome/environment" = { };
    sops.secrets."media/freshrss" = {
      owner = "freshrss";
    };
    sops.secrets."immich/secrets" = { };
    sops.secrets."remotebuilder/athena" = { };
    sops.secrets."remotebuilder/circe" = { };
    sops.secrets."admin/user" = { };
    sops.secrets."admin/pass" = { };
    sops.secrets."copyparty/foxtrot" = {
      owner = "copyparty";
    };

    sops.secrets."mollysocket/vapid_privkey" = {
      owner = "mollysocket";
    };
    sops.secrets."factorio_user" = {
      sopsFile = ../../secrets/nyx-nixos.json;

      format = "json";
    };

    sops.secrets."factorio_token" = {
      sopsFile = ../../secrets/nyx-nixos.json;

      format = "json";
    };

    sops.secrets."factorio_game_password" = {
      sopsFile = ../../secrets/nyx-nixos.json;

      format = "json";
    };

    sops.templates."factorio-credentials.json" = {
      content = ''
        {
          "username": "${config.sops.placeholder.factorio_user}",
          "token": "${config.sops.placeholder.factorio_token}",
          "game_password": "${config.sops.placeholder.factorio_game_password}"
        }
      '';

      owner = "server";
      restartUnits = [ "ofsm.service" ];
    };

    sops.secrets."samba-nyx/socks" = {
      mode = "0440";
      owner = config.users.users.server.name;
      group = config.users.users.server.group;
    };

    sops.secrets."samba-nyx/serena" = {
      mode = "0440";
      owner = config.users.users.server.name;
      group = config.users.users.server.group;
    };

    sops.secrets."samba-nyx/zia" = {
      mode = "0440";
      owner = config.users.users.server.name;
      group = config.users.users.server.group;
    };

    sops.secrets."syncthing/pass" = {
      owner = "syncthing";
      sopsFile = common;
    };

    sops.secrets."syncthing/nyx-nixos/cert" = { };
    sops.secrets."syncthing/nyx-nixos/key" = { };

  };

  flake.nixosModules.deckSops = { inputs, config, ... }:
    let
      common = ../../secrets/common.yaml;
    in
    {
    imports = [
      inputs.sops-nix.nixosModules.sops
    ];

    sops.defaultSopsFile = ../../secrets/${config.networking.hostName}.yaml;
    sops.defaultSopsFormat = "yaml";
    sops.useSystemdActivation = true;

    sops.age.keyFile = "${config.users.users.deck.home}/.config/sops/age/keys.txt";

    sops.secrets."samba/local" = {
      mode = "0440";
      owner = config.users.users.deck.name;
      group = config.users.users.deck.group;
      sopsFile = common;
    };

    sops.secrets."networks/bazinga/pass" = {
      sopsFile = common;
    };

    sops.secrets."attic/client-config" = {
      owner = config.users.users.deck.name;
      sopsFile = common;
    };

    sops.secrets."users/deck" = {
      neededForUsers = true;
    };
  };
}
