{ lib, pkgs, ... }:
{
  services.openssh = {
    enable = lib.mkForce true;
    ports = [ 2222 ];
    settings = {
      PasswordAuthentication = lib.mkForce false;
      AllowTcpForwarding = lib.mkForce "yes";
    };
    extraConfig = ''
      Match User tunnel
        AllowTcpForwarding yes
        X11Forwarding no
        AllowAgentForwarding no
        ForceCommand /run/current-system/sw/bin/false
        PermitTTY no
    '';
  };

  users.users.tunnel = {
    isSystemUser = true;
    group = "tunnel";
    shell = pkgs.shadow;
    openssh.authorizedKeys.keys = [
      ''restrict,port-forwarding ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJcAXHlW7WhNVvoU5H6q7BZDu09Tnd60P8QDJVhpbSiJ foxtrot@circe-nixos''
    ];
  };

  users.groups.tunnel = { };
}
