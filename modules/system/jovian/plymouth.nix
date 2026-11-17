{ inputs, ... }:
{
  flake.nixosModules.jovianPlymouth =
    {
      inputs,
      pkgs,
      lib,
      ...
    }:
    {
      boot.plymouth = {
        enable = true;
        theme = lib.mkForce "steamos";
        themePackages = with pkgs; [
          steamos-plymouth
        ];
      };

      boot.loader.timeout = 1;
      boot.loader.limine.extraConfig = ''
        quiet: yes
      '';
    };
}
