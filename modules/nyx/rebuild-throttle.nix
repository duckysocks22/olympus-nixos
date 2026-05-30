{ ... }:
{
  systemd.services.nix-daemon.serviceConfig = {
    CPUWeight = 20;
    IOWeight = 10;
    IOSchedulingClass = "idle";
    Nice = 19;
    MemoryHigh = "4G";
  };

  nix.settings = {
    max-jobs = 4;
    cores = 4;
  };

  systemd.services.sshd.serviceConfig.CPUWeight = 1000;
  systemd.services.adguardhome.serviceConfig = {
    CPUWeight = 1000;
    IOWeight = 1000;
  };
}
