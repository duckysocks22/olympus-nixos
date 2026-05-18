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
          ".config/ly"
          ".config/sops"
          ".config/noctalia"
          ".local/state/neovim"
          ".local/state/wireplumber"
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
          ".zsh_history"
          ".config/sops/age/keys.txt"
        ];
      };
    };
  };

  systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];

  systemd.tmpfiles.settings.preservation = {
    "/home/foxtrot/.config".d = { user = "foxtrot"; group = "users"; mode = "0755"; };
    "/home/foxtrot/.local".d = { user = "foxtrot"; group = "users"; mode = "0755"; };
    "/home/foxtrot/.local/share".d = { user = "foxtrot"; group = "users"; mode = "0755"; };
    "/home/foxtrot/.local/state".d = { user = "foxtrot"; group = "users"; mode = "0755"; };
  };
}
