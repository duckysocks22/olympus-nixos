{ inputs, self, ... }:
{
  flake.nixosModules.ariadneDisko =
    {
      inputs,
      lib,
      ...
    }:
    {
      imports = [ inputs.disko.nixosModules.disko ];

      disko.devices = {
        disk = {
          main = {
            device = "/dev/disk/by-id/nvme-Micron_2500_MTFDKBK2T0QGN_253953313CCE";
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
                    type = "swap";
                    resumeDevice = true;
                  };
                };
                luks = {
                  size = "100%";
                  content = {
                    type = "luks";
                    name = "crypted";
                    settings = {
                      allowDiscards = true;
                      crypttabExtraOpts = [ "tpm2-device=auto" ];
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
                        "/root" = {
                          mountOptions = [
                            "compress=zstd"
                            "subvol=root"
                            "noatime"
                          ];
                          mountpoint = "/";
                        };
                        "/nix" = {
                          mountOptions = [
                            "compress=zstd"
                            "subvol=nix"
                            "noatime"
                          ];
                          mountpoint = "/nix";
                        };
                        "/home" = {
                          mountOptions = [
                            "compress=zstd"
                            "subvol=home"
                            "noatime"
                          ];
                          mountpoint = "/home";
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
      fileSystems."/nix".neededForBoot = true;
      fileSystems."/persistent".neededForBoot = true;

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
