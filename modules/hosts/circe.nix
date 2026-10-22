{ inputs, self, ... }: {
  flake.nixosConfigurations.circe-nixos = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit inputs;
      pkgs-unstable = import inputs.nixpkgs-unstable {
        localSystem = "x86_64-linux";
        config.allowUnfree = true;
      };
    };
    modules = [
      self.nixosModules.circe
      self.nixosModules.circeHardware
      self.nixosModules.circeDisko
      self.nixosModules.functions
      self.nixosModules.preservation
      self.nixosModules.systemHarden
      self.nixosModules.dms-greeter
      self.nixosModules.system
      self.nixosModules.mouseModifiers
      self.nixosModules.foxtrot
      self.nixosModules.common
      self.nixosModules.defaultNetwork
      self.nixosModules.defaultSops
      self.nixosModules.virtualisation
      self.nixosModules.vmTest
      self.nixosModules.localPrinting
      self.nixosModules.localSamba
      self.nixosModules.buildClient
      self.nixosModules.i2pd
    ];
  };

  flake.nixosModules.circe =
    {
      config,
      lib,
      pkgs,
      inputs,
      ...
    }:
    let
      # Sleep-transaction markers on the ESP. A hibernation that never returns leaves a
      # bare hibernate-begin with no matching end, which is the signature of the hang;
      # a real S4 power-off is bracketed by begin, a fresh initrd boot, then end.
      resumeTraceLog = "/boot/resume-trace.log";
      resumeTrace = pkgs.writeShellScript "resume-trace" ''
        export PATH="${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.gnused}/bin"
        log=${resumeTraceLog}
        boot="$(cat /proc/sys/kernel/random/boot_id)"
        now="$(date +%s)"
        case "$1" in
          userspace)
            printf '%s stage=userspace boot=%s\n' "$(date -Is)" "$boot" >> "$log"
            ;;
          begin)
            printf '%s stage=hibernate-begin boot=%s t=%s\n' "$(date -Is)" "$boot" "$now" >> "$log"
            ;;
          end)
            begin="$(sed -n 's/.*stage=hibernate-begin .* t=\([0-9]*\).*/\1/p' "$log" 2>/dev/null | tail -n1)"
            if [ -n "$begin" ] && [ "$now" -ge "$begin" ]; then
              slept="$((now - begin))s"
            else
              slept=-
            fi
            lastInitrd="$(sed -n 's/.*stage=initrd .*boot=\([^ ]*\).*/\1/p' "$log" 2>/dev/null | tail -n1)"
            if [ -n "$lastInitrd" ] && [ "$lastInitrd" != "$boot" ]; then
              resumed=yes
            else
              resumed=no
            fi
            printf '%s stage=hibernate-end boot=%s resumed=%s slept=%s\n' "$(date -Is)" "$boot" "$resumed" "$slept" >> "$log"
            ;;
        esac
      '';
      wifiPmHooks = {
        ExecStartPre = [
          "-${pkgs.bash}/bin/sh -c 'echo 0000:62:00.0 > /sys/bus/pci/drivers/mt7921e/unbind'"
          "-${resumeTrace} begin"
        ];
        ExecStartPost = [
          "-${pkgs.bash}/bin/sh -c 'echo 0000:62:00.0 > /sys/bus/pci/drivers/mt7921e/bind'"
          "-${resumeTrace} end"
        ];
      };
      # Two separate resume bugs: niri drops the first frame while reacquiring DRM master,
      # and the quickshell lock surface keeps waiting on a pre-stall frame callback, so it
      # only repaints once input arrives. A synthetic Shift tap (no character) unblocks it.
      niriResumeRedraw = pkgs.writeShellScript "niri-resume-redraw" ''
        export XDG_RUNTIME_DIR="/run/user/$(id -u)"
        export WAYLAND_DISPLAY="$(basename "$(ls "$XDG_RUNTIME_DIR"/wayland-* 2>/dev/null | grep -v '\.lock' | head -1)")"
        sock=$(ls "$XDG_RUNTIME_DIR"/niri.wayland-*.sock 2>/dev/null | head -1)
        [ -n "$sock" ] || exit 0
        export NIRI_SOCKET="$sock"
        sleep 4
        ${pkgs.niri}/bin/niri msg action power-on-monitors >/dev/null 2>&1 || true
        ${pkgs.wtype}/bin/wtype -k Shift_L >/dev/null 2>&1 || true
        sleep 5
        ${pkgs.niri}/bin/niri msg action power-on-monitors >/dev/null 2>&1 || true
        ${pkgs.wtype}/bin/wtype -k Shift_L >/dev/null 2>&1 || true
        sleep 3
        ${pkgs.niri}/bin/niri msg action power-on-monitors >/dev/null 2>&1 || true
      '';
      # The initrd journal does not survive the image restore, so initrd progress goes to
      # the unencrypted ESP. Failures are echoed to the console because /dev/kmsg lives in
      # the memory the restore throws away. Timestamps here are UTC: the initrd has no tzdata.
      initrdTrace = ''
        trace_fail() { echo "resume-trace: $*" > /dev/console 2>/dev/null; }
        esp=""
        tries=0
        while [ -z "$esp" ] && [ "$tries" -lt 20 ]; do
          for candidate in /dev/disk/by-partlabel/disk-main-ESP /dev/nvme0n1p1; do
            if [ -b "$candidate" ]; then
              esp="$candidate"
              break
            fi
          done
          [ -n "$esp" ] || sleep 0.5
          tries=$((tries + 1))
        done
        if [ -z "$esp" ]; then
          trace_fail "no ESP device"
          exit 0
        fi
        mkdir -p /mnt
        if ! mount -t vfat -o rw "$esp" /mnt 2>/dev/null; then
          trace_fail "mount $esp failed"
          exit 0
        fi
        line="$(date -Is) stage=initrd boot=$(cat /proc/sys/kernel/random/boot_id)"
        line="$line resume=$(cat /sys/power/resume 2>/dev/null || echo -)"
        if [ -e /dev/mapper/crypted-swap ]; then
          line="$line swap=present"
        else
          line="$line swap=absent"
        fi
        if [ -e /sys/firmware/efi/efivars/HibernateLocation-8cf2644b-4b0b-428f-9387-6d876050dc67 ]; then
          line="$line img=yes"
        else
          line="$line img=no"
        fi
        printf '%s\n' "$line" >> /mnt/resume-trace.log
        if [ "$(tail -n1 /mnt/resume-trace.log 2>/dev/null)" != "$line" ]; then
          trace_fail "$esp write not verified"
        fi
        sync
        umount /mnt || umount -l /mnt
      '';
    in
    {

      environment.systemPackages =
        (with pkgs; [
          git
          wget
          vim
        ])
        ++ [
          self.packages.${pkgs.stdenv.hostPlatform.system}.greenlight
        ];
      networking.hostName = "circe-nixos";
      time.timeZone = "America/New_York";
      services = {
        xserver.xkb = {
          layout = "us";
          variant = "";
        };
        pulseaudio.enable = false;
        pipewire = {
          enable = true;
          alsa = {
            enable = true;
            support32Bit = true;
          };
          pulse.enable = true;
        };
        libinput.enable = true;
        logind.settings.Login = {
          HandleLidSwitch = "suspend-then-hibernate";
          HandleLidSwitchExternalPower = "suspend-then-hibernate";
        };
      };
      security.rtkit.enable = true;
      # This firmware never completes native ACPI S4: with the kernel default of
      # HibernateMode=platform the image is written but the machine stays powered
      # (backlight and keyboard lit, battery draining) until it is forced off, or the
      # platform bounces straight back before the image write. S5 does work, so power
      # down via shutdown instead of handing off to S4.
      systemd.sleep.settings.Sleep = {
        HibernateDelaySec = "1h";
        HibernateMode = "shutdown";
      };
      systemd.services.niri-resume-redraw = {
        description = "Repaint niri after resume";
        wantedBy = [
          "hibernate.target"
          "suspend.target"
          "suspend-then-hibernate.target"
          "hybrid-sleep.target"
        ];
        after = [
          "hibernate.target"
          "suspend.target"
          "suspend-then-hibernate.target"
          "hybrid-sleep.target"
        ];
        path = [ pkgs.coreutils ];
        serviceConfig = {
          Type = "oneshot";
          User = config.users.users.foxtrot.name;
          ExecStart = niriResumeRedraw;
        };
      };
      # mt7921e (0000:62:00.0) fails pci_pm_restore with -ETIMEDOUT on every hibernation
      # resume and can wedge the machine after thaw; keep it out of the driver's PM list.
      systemd.services.systemd-hibernate.serviceConfig = wifiPmHooks;
      systemd.services.systemd-suspend-then-hibernate.serviceConfig = wifiPmHooks;
      systemd.services.resume-trace-userspace = {
        description = "Trace: userspace reached";
        wantedBy = [ "sysinit.target" ];
        after = [ "local-fs.target" ];
        unitConfig.DefaultDependencies = "no";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${resumeTrace} userspace";
        };
      };
      boot.initrd.availableKernelModules = [
        "vfat"
        "nls_cp437"
        "nls_iso8859-1"
      ];
      boot.initrd.systemd.services.resume-trace-initrd = {
        description = "Trace: initrd reached, before attempting resume";
        wantedBy = [ "sysinit.target" ];
        wants = [
          "systemd-cryptsetup@crypted.service"
          "systemd-cryptsetup@crypted-swap.service"
        ];
        after = [
          "systemd-udevd.service"
          "systemd-cryptsetup@crypted.service"
          "systemd-cryptsetup@crypted-swap.service"
        ];
        before = [ "systemd-hibernate-resume.service" ];
        unitConfig.DefaultDependencies = "no";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = initrdTrace;
      };
      boot.kernelParams = [
        "pcie_aspm.policy=powersave"
        "iommu.passthrough=1"
      ];
      boot.kernel.sysctl = {
        "kernel.sysrq" = 1;
        "kernel.printk" = "7 4 1 7";
      };
      boot.kernelPatches = [
        {
          name = "hibernate-lz4";
          patch = null;
          structuredExtraConfig = {
            HIBERNATION_COMP_LZ4 = lib.kernel.yes;
            HIBERNATION_DEF_COMP = lib.kernel.freeform "lz4";
          };
        }
      ];

      nixpkgs.config.allowUnfree = true;
      system.stateVersion = "26.05";

      security.protectKernelImage = false;
      hardware.bluetooth.settings.Policy.AutoEnable = lib.mkForce false;
      systemd.services.waydroid-container.wantedBy = lib.mkForce [ ];
      systemd.services.libvirtd.wantedBy = lib.mkForce [ ];

      services.tuned = {
        profiles.circe-balanced-battery = {
          main.include = "balanced-battery";
          sysfs = {
            "/sys/class/platform-profile/platform-profile-0/profile" = "low-power";
          };
          sysctl = {
            "kernel.nmi_watchdog" = "0";
            "vm.dirty_writeback_centisecs" = "1500";
          };
        };
        ppdSettings.battery.balanced = "circe-balanced-battery";
      };

      virtualisation.vmVariantWithDisko = {
        boot.initrd.availableKernelModules = [ "virtio_gpu" ];
        boot.initrd.secrets."/tmp/luks-vm.key" = builtins.toFile "luks-vm.key" "disko";
        boot.initrd.luks.devices."crypted".keyFile = "/tmp/luks-vm.key";
        boot.initrd.luks.devices."crypted-swap".keyFile = "/tmp/luks-vm.key";
        users.users.root.initialPassword = "root";
      };
    };

  flake.nixosModules.circeDisko = { inputs, lib, ... }: {
    imports = [ inputs.disko.nixosModules.disko ];
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

  flake.nixosModules.circeHardware =
    {
      config,
      lib,
      pkgs,
      modulesPath,
      ...
    }:
    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
      ];

      boot = {
        kernelModules = [ "kvm-amd" ];
        extraModulePackages = [ ];
        initrd = {
          kernelModules = [ ];
          availableKernelModules = [
            "nvme"
            "xhci_pci"
            "thunderbolt"
          ];
        };
      };

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
