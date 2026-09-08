{ inputs, self, ... }: {
  flake.nixosModules.virtualisation = { config, pkgs, lib, ... }: {
    programs.virt-manager.enable = true;

    users.groups.libvirtd.members = [
      "foxtrot"
      "server"
    ];

    virtualisation = {
      libvirtd.enable = true;
      spiceUSBRedirection.enable = true;
      waydroid = {
        enable = true;
        package = pkgs.waydroid-nftables;
      };
    };

    environment.systemPackages = with pkgs; [
      guestfs-tools
      virtiofsd
      wl-clipboard
    ];
  };
}
