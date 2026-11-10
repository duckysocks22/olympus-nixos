{ inputs, self, ... }:
{
  flake.nixosModules.plymouth =
    {
      pkgs,
      ...
    }:
    {
      boot.plymouth = {
        enable = true;
        theme = "deus_ex";

        themePackages = with pkgs; [
          (adi1090x-plymouth-themes.override {
            selected_themes = [ "deus_ex" ];
          })
        ];

        extraConfig = ''
          [Daemon]
          DeviceScale = 1.0
        '';
      };
    };
}
