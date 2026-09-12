{ inputs, self, ... }: {
  flake.nixosModules.buildHost = { ... }: {
    users.users.remotebuild = {
      isNormalUser = true;
      createHome = false;
      group = "remotebuild";
      extraGroups = [ "nixbld" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMFCqhCYgJNuZ0+3oJFFmEjmUNSBPhLSzZfuHWjY2ivc root@ariadne-nixos"
      ];
    };
    users.groups.remotebuild = { };

    nix.settings.trusted-users = [ "remotebuild" ];
  };

  flake.nixosModules.buildClient = { ... }: {
    nix.distributedBuilds = true;
    nix.settings.builders-use-substitutes = true;

    nix.buildMachines = [
      {
        hostName = "172.17.100.1";
        sshUser = "remotebuild";
        sshKey = "/etc/ssh/ssh_host_ed25519_key";
        systems = [ "x86_64-linux" ];
        maxJobs = 8;
        speedFactor = 2;
        supportedFeatures = [ "kvm" "big-parallel" "benchmark" "nixos-test" "pipe-operators" ];
      }
    ];

    programs.ssh.knownHosts.nyx-nixos = {
      hostNames = [ "172.17.100.1" "nyx-nixos" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEeEqqcPRubu6LqVhSZQY63rv0ALqn8OY1UuLCXB2wfd";
    };
  };
}
