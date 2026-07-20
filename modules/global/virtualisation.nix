{ config, pkgs, ... }:
{
  programs.virt-manager.enable = true;

  users.groups.libvirtd.members = [
    "foxtrot"
    "server"
  ];

  users.users.foxtrot.extraGroups = [ "libvirtd" ];

  virtualisation.libvirtd.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;

  virtualisation.waydroid = {
    enable = true;
    package = pkgs.waydroid-nftables;
  };

  environment.systemPackages = with pkgs; [
    guestfs-tools
    virtiofsd
    wl-clipboard
  ];
}
