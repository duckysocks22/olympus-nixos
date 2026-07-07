{
  programs.ssh.extraConfig = ''
    Host nyx-nixos.local
      HostName nyx-nixos.local
      ConnectTimeout 5
    Port 2222
  '';

  nix.distributedBuilds = true;
  nix.settings = {
    fallback = true;
    builders-use-substitutes = true;
  };

  nix.buildMachines = [
    {
      hostName = "nyx-nixos.local";
      sshUser = "remotebuild";
      sshKey = "/root/.ssh/remotebuild";
      systems = [ "x86_64-linux" ];
      maxJobs = 4;
      speedFactor = 2;
      supportedFeatures = [ "nixos-test" "flakes" "big-parallel" "kvm" ];
    }
  ];
}
