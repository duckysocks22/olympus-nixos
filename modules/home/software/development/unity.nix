{ inputs, ... }:
{
  flake.homeModules.unity =
    {
      pkgs,
      ...
    }:
    {
      home.packages = [ pkgs.unityhub ];

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "x-scheme-handler/unityhub" = "unityhub.desktop";
        };
      };
    };
}
