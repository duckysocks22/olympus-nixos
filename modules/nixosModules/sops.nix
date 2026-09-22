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
    in
    {
      imports = [
        inputs.sops-nix.nixosModules.sops
      ];

      sops.defaultSopsFile = ../../secrets/secrets.yaml;
      sops.defaultSopsFormat = "yaml";
      sops.useSystemdActivation = true;

      sops.age.keyFile = "${config.users.users.foxtrot.home}/.config/sops/age/keys.txt";

      sops.secrets."samba/local".mode = "0440";
      sops.secrets."samba/local".owner = config.users.users.foxtrot.name;
      sops.secrets."samba/local".group = config.users.users.foxtrot.group;

      #sops.secrets."syncthing/circe/cert" = { owner = "syncthing"; path = "/run/secrets/syncthing/circe/cert.pem"; };
      #sops.secrets."syncthing/circe/key" = { owner = "syncthing"; path = "/run/secrets/syncthing/circe/key.pem"; };

      sops.secrets."netbird/client-key" = {
        owner = "foxtrot";
      };

      sops.secrets."work/network" = { };
      sops.secrets."work/user" = { };
      sops.secrets."work/pass" = { };
      sops.secrets."work/domain" = { };

      sops.secrets."bazinga/pass" = { };

      sops.secrets."attic/client-config".owner = config.users.users.foxtrot.name;

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
                SSID=$(cat ${config.sops.secrets."work/network".path})
                USER=$(cat ${config.sops.secrets."work/user".path})
                PASS=$(cat ${config.sops.secrets."work/pass".path})
                DOMAIN=$(cat ${config.sops.secrets."work/domain".path})

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

  flake.nixosModules.aetherSops = { inputs, config, ... }: {
    imports = [
      inputs.sops-nix.nixosModules.sops
    ];

    sops.defaultSopsFile = ../../secrets/secrets.yaml;
    sops.defaultSopsFormat = "yaml";

    sops.age.keyFile = "${config.users.users.server.home}/.config/sops/age/keys.txt";

    sops.secrets."users/server" = {
      neededForUsers = true;
    };

    sops.secrets."caddy/environment" = { };
    sops.secrets."caddy/ca-cert" = {
      owner = "caddy";
    };

    sops.secrets."attic/client-config".owner = config.users.users.server.name;
  };

  flake.nixosModules.serverSops = { inputs, config, ... }: {
    imports = [
      inputs.sops-nix.nixosModules.sops
    ];

    sops.defaultSopsFile = ../../secrets/secrets.yaml;
    sops.defaultSopsFormat = "yaml";

    sops.age.keyFile = "${config.users.users.server.home}/.config/sops/age/keys.txt";

    #sops.secrets."webdav/copyparty" = {
    #  path = "/etc/davfs2/secrets";
    #};

    sops.secrets."llama-cpp/api-key" = { mode = "644"; };

    sops.secrets."samba-nyx/socks" = { };
    sops.secrets."samba-nyx/serena" = { };
    sops.secrets."samba-nyx/zia" = { };
    sops.secrets."users/server" = { };
    sops.secrets."users/foxtrot" = { };
    sops.secrets."netbird/routing-key" = { };
    sops.secrets."caddy/environment" = { };
    sops.secrets."attic/server-token" = { };
    sops.secrets."attic/client-config".owner = config.users.users.server.name;
    sops.secrets."vaultwarden/env" = { };
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

    sops.secrets."media/tdarr/server_env" = {
      owner = "tdarr";
    };
    sops.secrets."media/tdarr/node_env" = {
      owner = "tdarr";
    };

    sops.secrets."syncthing/nyx/cert" = {
      owner = "syncthing";
      path = "/run/secrets/syncthing/nyx/cert.pem";
    };
    sops.secrets."syncthing/nyx/key" = {
      owner = "syncthing";
      path = "/run/secrets/syncthing/nyx/key.pem";
    };

    sops.secrets."adguardhome/domain_cert" = {
      owner = "server";
      path = "/media/hdd1/certs/dns.puppygirls.net/dns.puppygirls.net.crt";
    };
    sops.secrets."adguardhome/domain_key" = {
      owner = "server";
      path = "/media/hdd1/certs/dns.puppygirls.net/dns.puppygirls.net.key";
    };

    sops.secrets."factorio_user" = {
      sopsFile = ../../secrets/otherSecrets.json;

      format = "json";
    };

    sops.secrets."factorio_token" = {
      sopsFile = ../../secrets/otherSecrets.json;

      format = "json";
    };

    sops.secrets."factorio_game_password" = {
      sopsFile = ../../secrets/otherSecrets.json;

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

    sops.secrets."users/server".neededForUsers = true;

    #sops.secrets."copyparty/foxtrot" = {
    #  mode = "0440";
    #  owner = "copyparty";
    #};

    sops.secrets."samba-nyx/socks".mode = "0440";
    sops.secrets."samba-nyx/socks".owner = config.users.users.server.name;
    sops.secrets."samba-nyx/socks".group = config.users.users.server.group;

    sops.secrets."samba-nyx/serena".mode = "0440";
    sops.secrets."samba-nyx/serena".owner = config.users.users.server.name;
    sops.secrets."samba-nyx/serena".group = config.users.users.server.group;

    sops.secrets."samba-nyx/zia".mode = "0440";
    sops.secrets."samba-nyx/zia".owner = config.users.users.server.name;
    sops.secrets."samba-nyx/zia".group = config.users.users.server.group;

    #sops.secrets."netbird/routing-key".owner = "netbird";
    #sops.secrets."netbird/routing-key".group = "netbird";

  };

  flake.nixosModules.deckSops = { inputs, config, ... }: {
    imports = [
      inputs.sops-nix.nixosModules.sops
    ];

    sops.defaultSopsFile = ../../secrets/secrets.yaml;
    sops.defaultSopsFormat = "yaml";
    sops.useSystemdActivation = true;

    sops.age.keyFile = "${config.users.users.deck.home}/.config/sops/age/keys.txt";

    sops.secrets."samba/local".mode = "0440";
    sops.secrets."samba/local".owner = config.users.users.deck.name;
    sops.secrets."samba/local".group = config.users.users.deck.group;

    sops.secrets."bazinga/pass" = { };

    sops.secrets."attic/client-config".owner = config.users.users.deck.name;
  };
}
