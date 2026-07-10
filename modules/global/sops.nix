{ inputs, config, ...}:
{
  imports =
    [
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

  systemd.services.iwd-hidden-profile = {
    description = "Dynamically generate IWD profile for Work Network";
    wantedBy = [ "multi-user.target" ];
    before = [ "iwd.service" "NetworkManager.service" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      SSID=$(cat ${config.sops.secrets."work/network".path})
      USER=$(cat ${config.sops.secrets."work/user".path})
      PASS=$(cat ${config.sops.secrets."work/pass".path})

      TARGET_FILE="/var/lib/iwd/$SSID.8021x"

      cat <<EOF > "$TARGET_FILE"
[Security]
EAP-Method=PEAP
EAP-Identity=$USER
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
}
