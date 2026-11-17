{ inputs, self, ... }:
{
  flake.nixosModules.qemu =
    {
      pkgs,
      lib,
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

      systemd.services.libvirtd.wantedBy = lib.mkForce [ ];
    };
}
