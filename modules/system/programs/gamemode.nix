{
  flake.nixosModules.gamemode =
    {
      config,
      pkgs,
      ...
    }:
    {
      programs.gamemode = {
        enable = true;
        settings = {
          general = {
            reaper_freq = 5;
            desiredgove = "powersave";
            desiredprof = "performance";
            igpu_desiredgov = -1;
            igpu_power_threshold = 0.3;
            softrealtime = "off";
            renice = 0;
            ioprio = 0;
            inhibit_screensaver = 1;
            disable_splitlock = 1;
          };
          gpu = {
            apply_gpu_optimisations = 0;
            amd_performance_leve = "high";
          };
          cpu = {
            #park_cores = no;
            #pin_cores = yes;
          };
        };
      };
    };
}
