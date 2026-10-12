{ inputs, self, ... }: {
  flake.nixosModules.virtualisation =
    {
      config,
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

      virtualisation.podman = {
        enable = true;
        dockerCompat = true;
        dockerSocket.enable = true;
        defaultNetwork.settings.dns_enabled = true;
      };
      users.users.foxtrot.extraGroups = [ "podman" ];
    };
}
