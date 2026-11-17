{ inputs, self, ... }:
{
  flake.nixosModules.nvidia =
    {
      config,
      pkgs,
      ...
    }:
    {
      hardware = {
        graphics = {
          enable = true;
          extraPackages = with pkgs; [
            nvidia-vaapi-driver
            libva-vdpau-driver
            libvdpau-va-gl
            libva-utils
          ];
        };

        nvidia = {
          open = true;
          modesetting.enable = true;
          package =
            let
              base = config.boot.kernelPackages.nvidiaPackages.bleeding_edge;
            in
            base
            // {
              open = base.open.overrideAttrs (old: {
                patches = (old.patches or [ ]) ++ [ ../../../patches/nvidia-open-kernel-7.2.patch ];
              });
            };
        };
      };

      services.xserver.videoDrivers = [ "nvidia" ];
    };
}
