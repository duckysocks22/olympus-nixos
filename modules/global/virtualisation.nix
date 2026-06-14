{ config, pkgs, ...}:
{
  programs.virt-manager.enable = true;

  users.groups.libvirtd.members = [ "foxtrot" "server" ];

  users.users.foxtrot.extraGroups = [ "libvirtd" ];

  virtualisation.libvirtd.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;
  
  environment.systemPackages = with pkgs; [
    guestfs-tools
    virtiofsd
  ];
}
