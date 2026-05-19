{
  config,
  lib,
  pkgs,
  ...
}:
{
  preservation = {
    enable = true;

    preserveAt."/persistent" = {

      # preserve system directories
      directories = [
        "/var/lib/bluetooth"
        "/var/lib/libvirt"
        "/var/lib/systemd/coredump"
        "/var/lib/systemd/rfkill"
        "/var/lib/systemd/timers"
        "/var/log"
        { directory = "/var/lib/nixos"; inInitrd = true; }
      ];

      # preserve system files
      files = [
        { file = "/etc/machine-id"; inInitrd = true; }
        { file = "/etc/ssh/ssh_host_rsa_key"; how = "symlink"; configureParent = true; }
        { file = "/etc/ssh/ssh_host_ed25519_key"; how = "symlink"; configureParent = true; }
      ];

      # preserve user-specific files, implies ownership
      users = {
        foxtrot = {
          commonMountOptions = [
            "x-gvfs-hide"
          ];
          directories = [
            { directory = ".ssh"; mode = "0700"; }
            ".config/sops"
            ".local/state/nvim"
	    ".local/state/neovim"
            ".local/state/wireplumber"
            ".local/share/direnv"
	    ".local/state/home-manager"
            ".local/state/nix"
	    ".local/share"
            ".mozilla"
	    ".factorio"
	    "Desktop"
	    "Documents"
	    "Downloads"
	    "Music"
	    "Pictures"
	    "Videos"

          ];
          files = [
            ".histfile"
	    "zsh_history"
          ];
        };
        root = {
          # specify user home when it is not `/home/${user}`
          home = "/root";
          directories = [
            { directory = ".ssh"; mode = "0700"; }
          ];
        };
      };
    };
  };
  systemd.tmpfiles.settings.preservation = {
    "/home/foxtrot/.config".d = { user = "foxtrot"; group = "users"; mode = "0755"; };
    "/home/foxtrot/.local".d = { user = "foxtrot"; group = "users"; mode = "0755"; };
    "/home/foxtrot/.local/share".d = { user = "foxtrot"; group = "users"; mode = "0755"; };
    "/home/foxtrot/.local/state".d = { user = "foxtrot"; group = "users"; mode = "0755"; };
  };
}
