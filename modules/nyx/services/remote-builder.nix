{ config, ... }:
{
  users.users.remotebuild = {
    isSystemUser = true;
    group = "remotebuild";
    useDefaultShell = true;

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPz78vmIb59Qjj6QmYgxv9LXIotxAcV8SYszBDKGJIgj root@athena-nixos"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOfjofk11ezfCgVeRCiSAgV2Q8S8aa4JMjiulSjE4aM8 root@circe-nixos"
    ];
  };

  users.groups.remotebuild = { };

  nix = {
    nrBuildUsers = 64;
    settings = {
      trusted-users = [ "remotebuild" ];
    };
  };
}
