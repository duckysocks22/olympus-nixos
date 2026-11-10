{ inputs, self, ... }:
{
  flake.nixosModules.qemu =
    {
      pkgs,
      ...
    }:
    {
      programs.virt-manager.enable = true;
      users.groups.libvirtd.members = [
        "foxtrot"
        "server"
      ];

      virtualisation = {
        libvirtd.enable = true;
        spiceUSBRedirection.enable = true;
      };

      environment.systemPackages = with pkgs; [
        guestfs-tools
        virtiofsd
        wl-clipboard
      ];
    };
}
