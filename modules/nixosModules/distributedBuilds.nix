{ inputs, self, ... }: {
  flake.nixosModules.buildHost =
    let
      nixServeCommand = "restrict,command=\"/run/current-system/sw/bin/nix-store --serve --write\" ";
      nixServeKey = key: nixServeCommand + key;
    in
    {
      users.users.remotebuild = {
        isNormalUser = true;
        createHome = false;
        group = "remotebuild";
        extraGroups = [ "nixbld" ];
        openssh.authorizedKeys.keys = [
          (nixServeKey "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAVF7dMsquwXmzdfKtFuD5KJ7SLeftFhl5Ezh1Rf0Aej root@dionysus-nixos")
          (nixServeKey "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMFCqhCYgJNuZ0+3oJFFmEjmUNSBPhLSzZfuHWjY2ivc root@ariadne-nixos")
          (nixServeKey "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP0iFfMsPQAbz7QOqgBnZQsJPjVXXq9djMm23+2mnETB root@aether-nixos")
          (nixServeKey "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKfMy/c6fka9VpW0hv6eJ7sMKOjDgSblpRcBUxDUvDlo root@circe-nixos")
        ];
      };
      users.groups.remotebuild = { };

      nix.settings.trusted-users = [ "remotebuild" ];
    };

  flake.nixosModules.buildClient =
    { config, lib, ... }:
    let
      # 192.168.10.253 is nyx's WireGuard-mesh address, reachable only by
      # mesh members (aether, circe). LAN clients use nyx's LAN address instead.
      builderHostName =
        if builtins.elem config.networking.hostName [ "aether-nixos" "circe-nixos" ] then "192.168.10.253" else "172.17.100.1";
    in
    {
      nix.distributedBuilds = true;
      nix.settings.builders-use-substitutes = true;

      programs.ssh.extraConfig = ''
        Host 192.168.10.253
          Compression yes

        Host 172.17.100.1
          ConnectTimeout 10
      '';

      nix.buildMachines =
        let
          mkMachine = hostName: speedFactor: {
            inherit hostName speedFactor;
            sshUser = "remotebuild";
            sshKey = "/etc/ssh/ssh_host_ed25519_key";
            systems = [ "x86_64-linux" ];
            maxJobs = 8;
            supportedFeatures = [
              "kvm"
              "big-parallel"
              "benchmark"
              "nixos-test"
              "pipe-operators"
            ];
          };
        in
        (lib.optional (config.networking.hostName == "circe-nixos") (mkMachine "172.17.100.1" 4))
        ++ [ (mkMachine builderHostName 2) ]
        ++ (lib.optional (config.networking.hostName == "dionysus-nixos") (mkMachine "192.168.10.253" 1));

      programs.ssh.knownHosts.nyx-nixos = {
        hostNames = [
          "172.17.100.1"
          "192.168.10.253"
        ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEeEqqcPRubu6LqVhSZQY63rv0ALqn8OY1UuLCXB2wfd";
      };
    };
}
