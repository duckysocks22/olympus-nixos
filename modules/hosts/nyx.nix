{ inputs, self, ... }: {
  flake.nixosConfigurations.nyx-nixos = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit inputs;
      pkgs-unstable = import inputs.nixpkgs-unstable {
        localSystem = "x86_64-linux";
        config.allowUnfree = true;
      };
    };
    modules = [
      self.nixosModules.nyx
      self.nixosModules.nyxHardware
      self.nixosModules.serverNetwork
      self.nixosModules.functions
      self.nixosModules.system
      self.nixosModules.nvidia
      self.nixosModules.server
      self.nixosModules.serverSops
      self.nixosModules.virtualisation
      self.nixosModules.serverMedia
      self.nixosModules.web
      self.nixosModules.automation
      self.nixosModules.gameServers
      self.nixosModules.files
      self.nixosModules.buildHost
    ];
  };

  flake.nixosModules.nyx =
    {
      config,
      pkgs,
      inputs,
      lib,
      ...
    }:
    {
      users.mutableUsers = false;
      users.users.root.hashedPasswordFile = config.sops.secrets."users/server".path;

      systemd.sleep.settings.Sleep = {
        AllowSuspend = false;
        AllowHibernation = false;
        AllowHybridSleep = false;
        AllowSuspendThenHibernation = false;
      };

      networking.hostName = "nyx-nixos";
      networking.useDHCP = lib.mkForce false;

      # Host runs AdGuardHome on :53; resolved's stub listeners (127.0.0.53/127.0.0.54)
      # block its wildcard bind. Point host DNS at AdGuard instead.
      services.resolved.enable = false;
      networking.resolvconf.useLocalResolver = true;
      networking.networkmanager.insertNameservers = [ "127.0.0.1" ];

      time.timeZone = "America/New_York";
      i18n = {
        defaultLocale = "en_US.UTF-8";
        extraLocaleSettings = {
          LC_ADDRESS = "en_US.UTF-8";
          LC_IDENTIFICATION = "en_US.UTF-8";
          LC_MEASUREMENT = "en_US.UTF-8";
          LC_MONETARY = "en_US.UTF-8";
          LC_NAME = "en_US.UTF-8";
          LC_NUMERIC = "en_US.UTF-8";
          LC_PAPER = "en_US.UTF-8";
          LC_TELEPHONE = "en_US.UTF-8";
          LC_TIME = "en_US.UTF-8";
        };
      };

      services = {
        xserver.xkb = {
          layout = "us";
          variant = "";
        };
        openssh.enable = true;
      };

      nixpkgs.config.allowUnfree = true;
      environment.systemPackages = with pkgs; [
        vim
        wget
        git
      ];

      system.stateVersion = "26.05";
    };

  flake.nixosModules.nyxHardware =
    {
      config,
      lib,
      pkgs,
      modulesPath,
      ...
    }:
    {
      imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

      boot = {
        initrd.availableKernelModules = [
          "nvme"
          "xhci_pci"
          "ahci"
          "usbhid"
          "sd_mod"
        ];
        initrd.kernelModules = [ ];
        kernelModules = [ "kvm-amd" ];
        extraModulePackages = [ ];
      };

      fileSystems."/" = {
        device = "/dev/disk/by-uuid/e52fc7d2-ca39-4502-8f55-2a9522eae878";
        fsType = "ext4";
      };

      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/8DE9-AB27";
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };

      fileSystems."/media/hdd1" = {
        device = "/dev/disk/by-uuid/f269dd7a-3b90-4927-99ae-201fcfdda001";
        fsType = "btrfs";
      };

      swapDevices = [
        { device = "/dev/disk/by-uuid/68518eb1-5d79-48e6-9595-eff62acd6a5f"; }
      ];

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
