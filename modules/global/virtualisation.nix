{ inputs, ... }:
{
  flake.nixosModules.virtualisation = { config, ... }: {
    programs.virt-manager.enable = true;

    users.groups.libvirtd.members = [ "foxtrot" "server" ];

    users.users.foxtrot.extraGroups = [ "libvirtd" ];

    virtualisation.libvirtd.enable = true;
    virtualisation.spiceUSBRedirection.enable = true;
  };
}
