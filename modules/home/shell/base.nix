{ inputs, self, ... }:
{
  flake.homeModules.baseShell =
    {
      pkgs,
      pkgs-unstable,
      config,
      inputs,
      ...
    }:
    let
      attic-client = pkgs-unstable.attic-client;
    in
    {
      imports = [
        self.homeModules.fish
        self.homeModules.git
        self.homeModules.download
        self.homeModules.atuin
        inputs.nix-index-database.homeModules.default
      ];

      home.packages = with pkgs; [
        ripgrep
        zellij
        elmPackages.nodejs
        jp2a
        shellcheck
        dust
        rclone
        attic-client
        gh
        btop
        cdrdao
        tldr
      ];

      dconf.settings = {
        "org/virt-manager/virt-manager/connections" = {
          autoconnect = [ "qemu:///system" ];
          uris = [ "qemu:///system" ];
        };
      };

      programs.nix-index-database.comma.enable = true;

      xdg.configFile."attic/config.toml" = {
        source = config.lib.file.mkOutOfStoreSymlink "/run/secrets/attic/client-config";
        force = true;
      };
    };
}
