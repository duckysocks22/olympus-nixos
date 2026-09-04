{ inputs, ... }: {
  flake.nixosModules.preservation = { config, lib, pkgs, ... }: {
    preservation = {
      enable = true;

      directories = [
        "/var/lib/bluetooth"
        "/var/lib/libvirt"
        "/var/lib/systemd/backlight"
        "/var/lib/systemd/coredump"
        "/var/lib/systemd/rfkill"
        "/var/lib/systemd/timers"
        "/var/lib/waydroid"
        {
          directory = "/var/lib/iwd/";
          mode = "700";
        }
        {
          directory = "/etc/NetworkManager/system-connections";
          mode = "700";
        }
        {
          directory = "/etc/libvirt";
          mode = "755";
        }
        {
          directory = "/var/lib/nixos";
          inInitrd = true;
        }
        "/var/cache/mullvad-vpn"
        "/var/log"
        "/etc/mullvad-vpn"
      ];

      files = [
        {
          file = "/etc/machine-id";
          inInitrd = true;
        }
        {
          file = "/etc/ssh/ssh_host_rsa_key";
          how = "symlink";
          configureParent = true;
        }
        {
          file = "/etc/ssh/ssh_host_ed25519_key";
          how = "symlink";
          configureParent = true;
        }
      ];

      users = {
        foxtrot = {
          commonMountOptions = [
            "x-gvfs-hide"
          ];
          directories = [
            {
              directory = ".ssh";
              mode = "0700";
            }
            ".mozilla"
            ".cache/DankMaterialShell"
            ".cache/nvim"
            ".cache/neovim"
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
            ".config/DankMaterialShell"
            ".config/Signal"
            ".config/discord"
            ".config/Vencord"
            ".config/attic"
            ".config/git"
            ".config/heroic"
            ".config/mozilla"
            ".conig/filezilla"
            ".config/sunshine"
            ".config/blender"
            ".config/unity3d"
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
            ".MakeMKV"
            "Unity"
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
          home = "/root";
          directories = [
            {
              directory = ".ssh";
              mode = "0700";
            }
          ];
        };
      };
    };
  };
  systemd.services."systemd-machine-id-commit".enable = false;

  systemd.tmpfiles.settings.preservation = {
    "/home/foxtrot/.config".d = {
      user = "foxtrot";
      group = "users";
      mode = "0755";
    };
    "/home/foxtrot/.local".d = {
      user = "foxtrot";
      group = "users";
      mode = "0755";
    };
    "/home/foxtrot/.local/state".d = {
      user = "foxtrot";
      group = "users";
      mode = "0755";
    };
    
    systemd.services."systemd-backlight@.service".after = [ "preservation.target" ];
  };
}
