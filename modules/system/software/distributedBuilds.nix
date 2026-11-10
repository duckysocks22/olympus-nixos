{ inputs, self, ... }:
{
  flake.nixosModules.buildClient =
    {
      config,
      lib,
      ...
    }:
    let
      builderHostName =
        if
          builtins.elem config.networking.hostName [
            "aether-nixos"
            "circe-nixos"
          ]
        then
          "192.168.10.253"
        else
          "172.17.100.1";
    in
    {
      sops.secrets."remotebuild/privateKey" = {
        sopsFile = ../../../secrets/${config.networking.hostName}.yaml;
        mode = "0600";
        restartUnits = [ "nix-daemon.service" ];
      };

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
            sshKey = config.sops.secrets."remotebuild/privateKey".path;
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
