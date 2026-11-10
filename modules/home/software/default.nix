{ inputs, self, ... }:
{
  flake.homeModules.software =
    {
      config,
      pkgs,
      ...
    }:
    {
      home.packages =
        (with pkgs; [
          fastfetch
          unrar
          p7zip
          filezilla
          lunatask
          simple-scan
          futo-notes
        ])
        ++ (with pkgs.kdePackages; [
          dolphin
          kate
          okular
        ]);

      programs.kitty = {
        enable = true;

        settings = {
          confirm_os_window_close = 0;
        };
      };
    };
}
