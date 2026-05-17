{
  boot.tmp.cleanOnBoot = true;

  preservation = {
    enable = true;
    preserveAt."/persistent" = {
      directories = [
        "/var/lib/systemd/timers"
        "/var/lib/nixos"
        "/var/log"
        "/var/lib/bluetooth"
        "/etc/NetworkManager/system-connections"
        "/tmp"
        "/run/secrets"
        "/run/secrets-for-users"
      ];

      files = [
        {
          file = "/etc/machine-id";
          inInitrd = true;
        }
      ];

      users.foxtrot = {
        directories = [
          ".ssh"
          ".mozilla"
          ".steam"
          ".factorio"
          ".local/share"
          ".config/sops"
          "olympus-nixos"
          "Documents"
          "Downloads"
          "Pictures"
          "Videos"
        ];

        files = [

        ];
      };
    };
  };
}
