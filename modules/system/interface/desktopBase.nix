{ inputs, self, ... }:
{
  flake.nixosModules.desktopBase =
    { pkgs, ... }:
    {
      services = {
        pulseaudio.enable = false;

        pipewire = {
          enable = true;
          alsa = {
            enable = true;
            support32Bit = true;
          };
        };

        libinput.enable = true;
      };

      security.rtkit.enable = true;
    };
}
