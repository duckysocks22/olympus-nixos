{ inputs, self, ... }:
{
  flake.nixosModules.defaultSops =
    {
      inputs,
      config,
      pkgs,
      ...
    }:
    let
      iwdCaBundle = pkgs.runCommand "iwd-ca-certificates.pem" { } ''
        awk '/^-----BEGIN CERTIFICATE-----$/,/^-----END CERTIFICATE-----$/' \
          ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt > $out
      '';
      common = ../../../../secrets/common.yaml;
    in
    {
      imports = [
        inputs.sops-nix.nixosModules.sops
      ];

      sops.defaultSopsFile = ../../../../secrets/${config.networking.hostName}.yaml;
      sops.defaultSopsFormat = "yaml";
      sops.useSystemdActivation = true;

      sops.age.keyFile =
        if config.preservation.enable or false then
          "/var/lib/sops-nix/key.txt"
        else
          "${config.users.users.foxtrot.home}/.config/sops/age/keys.txt";

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
}
