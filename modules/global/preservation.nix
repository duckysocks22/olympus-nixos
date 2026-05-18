{
  boot.tmp.useTmpfs = true;

  preservation = {
    enable = true;
    preserveAt."/persistent" = {
      directories = [
        "/var/lib/systemd/timers"
        "/var/lib/nixos"
        "/var/log"
        "/var/lib/bluetooth"
        "/etc/NetworkManager/system-connections"
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
          ".config"
          ".config/noctalia"
          ".local/state/neovim"
          "olympus-nixos"
          "git"
          "Documents"
          "Downloads"
          "Pictures"
          "Videos"
          "Desktop"
          "HomeRips"
        ];

        files = [

        ];
      };
    };
  };

  systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
}
