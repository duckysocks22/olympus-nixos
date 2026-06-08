{
  programs.ssh.extraConfig = ''
    Host ssh.olympus.moe
      HostName ssh.olympus.moe
    Port 2222
  '';

  nix.distributedBuilds = true;

  nix.buildMachines = [
    {
      hostName = "ssh.olympus.moe";
      sshUser = "remotebuild";
      sshKey = "/root/.ssh/remotebuild";
      systems = [ "x86_64-linux" ];
      maxJobs = 4;
      speedFactor = 2;
      supportedFeatures = [ "nixos-test" "big-parallel" "kvm" ];
    }
  ];
}
