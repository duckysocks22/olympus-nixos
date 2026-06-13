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
        { directory = "/var/lib/iwd/"; mode = "700"; }
        { directory = "/etc/NetworkManager/system-connections"; mode = "700"; }
        { directory = "/var/lib/netbird-${config.networking.hostName}"; mode = "0777"; }
        { directory = "/etc/libvirt"; mode = "755"; }
        "/var/log"
        { directory = "/var/lib/nixos"; inInitrd = true; }
        { directory = "/sys/class/backlight"; inInitrd = true; }
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
            ".claude"
            ".mozilla"
            ".thunderbird"
            ".cache/noctalia"
            ".config/DankMaterialShell"
            ".cache/DankMaterialShell"
            ".cache/nvim"
            ".cache/neovim"
            ".cache/thunderbird"
            ".cache/protonmail"
            ".cache/mesa_shader_cache"
            ".cache/mesa_shader_cache_db"
            ".cache/radv_builtin_shaders"
            ".cache/AMD"
            ".cache/nv"
            ".cache/nvidia"
            ".cache/dxvk-cache"
            ".cache/vkcache"
            ".cache/wine"
            ".cache/winetricks"
            ".config/sops"
            ".config/discord"
            ".config/attic"
            ".config/netbird"
            ".config/git"
            ".config/heroic"
            ".config/mozilla"
            ".config/thunderbird"
            ".config/protonmail"
            ".local/state/nvim"
	    ".local/state/neovim"
            ".local/state/wireplumber"
            ".local/share/direnv"
	    ".local/state/home-manager"
            ".local/state/nix"
	    ".local/share"
	    ".factorio"
            ".steam"
            ".xlcore"
            "olympus-nixos"
	    "Desktop"
	    "Documents"
	    "Downloads"
	    "Music"
	    "Pictures"
	    "Videos"
          ];
          files = [
            ".histfile"
	    ".zsh_history"
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
  # machine-id is preserved to /persistent (real fs), so the service that
  # commits a transient tmpfs machine-id to disk will always fail. Disable it.
  systemd.services."systemd-machine-id-commit".enable = false;

  systemd.tmpfiles.settings.preservation = {
    "/home/foxtrot/.config".d = { user = "foxtrot"; group = "users"; mode = "0755"; };
    "/home/foxtrot/.local".d = { user = "foxtrot"; group = "users"; mode = "0755"; };
    "/home/foxtrot/.local/state".d = { user = "foxtrot"; group = "users"; mode = "0755"; };
  };
}
