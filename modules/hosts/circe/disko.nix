{ inputs, self, ... }:
{
  flake.nixosModules.circeDisko =
    {
      inputs,
      lib,
      ...
    }:
    {
      imports = [
        inputs.disko.nixosModules.disko
        inputs.self.nixosModules.diskoVM
      ];

      disko.devices = {
        disk = {
          main = {
            device = "/dev/disk/by-id/nvme-SAMSUNG_MZVL81T0HFLB-00BH1_S7T8NF0Y375930";
            type = "disk";
            imageSize = "40G";
            content = {
              type = "gpt";
              partitions = {
                ESP = {
                  name = "ESP";
                  size = "1G";
                  type = "EF00";

                  content = {
                    type = "filesystem";
                    format = "vfat";
                    mountpoint = "/boot";
                  };
                };
                swap = {
                  size = "16G";
                  content = {
                    type = "luks";
                    name = "crypted-swap";
                    settings = {
                      allowDiscards = true;
                    };
                    content = {
                      type = "swap";
                      resumeDevice = true;
                    };
                  };
                };
                luks = {
                  size = "100%";
                  content = {
                    type = "luks";
                    name = "crypted";
                    settings = {
                      allowDiscards = true;
                    };
                    content = {
                      type = "btrfs";
                      extraArgs = [ "-f" ];
                      subvolumes = {
                        "/persistent" = {
                          mountOptions = [
                            "subvol=persistent"
                            "noatime"
                          ];
                          mountpoint = "/persistent";
                        };
                        "/nix" = {
                          mountOptions = [
                            "compress=zstd"
                            "subvol=nix"
                            "noatime"
                          ];
                          mountpoint = "/nix";
                        };
                        "/root" = {
                          mountOptions = [
                            "compress=zstd"
                            "subvol=root"
                            "noatime"
                          ];
                          mountpoint = "/";
                        };
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };

      boot.initrd.systemd.enable = lib.mkForce true;
      fileSystems."/nix".neededForBoot = true;
      fileSystems."/persistent".neededForBoot = true;

      # Wipe root subvolume on boot
      boot.initrd.systemd.services.wipe-root = {
        description = "Reset btrfs root subvol for stateless boot";
        wantedBy = [ "initrd-root-device.target" ];
        before = [ "sysroot.mount" ];
        after = [
          "dev-mapper-crypted.device"
          "local-fs-pre.target"
        ];
        unitConfig.DefaultDependencies = "no";
        serviceConfig.Type = "oneshot";
        script = ''
          mount --mkdir -o subvol=/ /dev/mapper/crypted /btrfs_tmp
          if [[ -e /btrfs_tmp/root ]]; then
            mkdir -p /btrfs_tmp/old_roots
            timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%d_%H:%M:%S")
            mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
          fi
          for old_root in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mindepth 1 -mtime +7); do
            btrfs subvolume delete --recursive "$old_root"
          done
          btrfs subvolume create /btrfs_tmp/root
          umount /btrfs_tmp
        '';
      };
    };
}
