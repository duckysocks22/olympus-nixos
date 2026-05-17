{
  preservation = {
    enable = true;
    preserveAt."/persistent" = {
      directories = [
        "/etc/nixos"
        "/var/lib/bluetooth"
        {
          directory = "/var/lib/nixos";
          inInitrd = true;
        }
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
