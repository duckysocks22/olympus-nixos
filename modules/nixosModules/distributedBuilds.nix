{ inputs, self, ... }: {
  flake.nixosModules.buildHost =
    let
      nixServeCommand =
        "restrict,command=\"/run/current-system/sw/bin/nix-store --serve --write\" ";
      nixServeKey = key: nixServeCommand + key;
    in
    {
      users.users.remotebuild = {
      isNormalUser = true;
      createHome = false;
      group = "remotebuild";
      extraGroups = [ "nixbld" ];
      openssh.authorizedKeys.keys = [
        (nixServeKey "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO8yfaT4Vc5wUoFx1jzNZoKXBiLGsqxuTndqz/9M3NdB root@dionysus-nixos")
        (nixServeKey "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMFCqhCYgJNuZ0+3oJFFmEjmUNSBPhLSzZfuHWjY2ivc root@ariadne-nixos")
        (nixServeKey "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP0iFfMsPQAbz7QOqgBnZQsJPjVXXq9djMm23+2mnETB root@aether-nixos")
        (nixServeKey "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO7f9ImZW+fkfzIxW9ZVfcjiUE5NUN+qnYlkpk+mr2F3 root@circe-nixos")
      ];
    };
    users.groups.remotebuild = { };

    nix.settings.trusted-users = [ "remotebuild" ];
  };

  flake.nixosModules.buildClient =
    { config, ... }:
    let
      # 192.168.10.253 is nyx's WireGuard-mesh address, reachable only by
      # mesh members (aether). LAN clients use nyx's LAN address instead.
      builderHostName =
        if config.networking.hostName == "aether-nixos"
        then "192.168.10.253"
        else "172.17.100.1";
    in
    {
      nix.distributedBuilds = true;
      nix.settings.builders-use-substitutes = true;

      nix.buildMachines = [
        {
          hostName = builderHostName;
          sshUser = "remotebuild";
          sshKey = "/etc/ssh/ssh_host_ed25519_key";
          systems = [ "x86_64-linux" ];
          maxJobs = 8;
          speedFactor = 2;
          supportedFeatures = [
            "kvm"
            "big-parallel"
            "benchmark"
            "nixos-test"
            "pipe-operators"
          ];
        }
      ];

      programs.ssh.knownHosts.nyx-nixos = {
        hostNames = [
          "172.17.100.1"
          "192.168.10.253"
        ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEeEqqcPRubu6LqVhSZQY63rv0ALqn8OY1UuLCXB2wfd";
      };
    };
}
