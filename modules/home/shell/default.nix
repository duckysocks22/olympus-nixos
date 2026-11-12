{ inputs, self, ... }:
{
  flake.homeModules.shell =
    {
      pkgs,
      config,
      inputs,
      pkgs-unstable,
      ...
    }:
    let
      attic-client = pkgs-unstable.attic-client;
    in
    {
      imports = [
        inputs.nix-index-database.homeModules.nix-index

        inputs.self.homeModules.fish
        inputs.self.homeModules.ssh
        inputs.self.homeModules.fastfetch
        inputs.self.homeModules.direnv
        inputs.self.homeModules.ranger
        inputs.self.homeModules.fzf
        inputs.self.homeModules.git
        inputs.self.homeModules.download
        inputs.self.homeModules.atuin
      ];

      programs.nix-index-database.comma.enable = true;

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

      xdg.configFile."fastfetch/ascii.txt".source = "${
        inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.assets
      }/share/assets/ascii.txt";

      xdg.configFile."attic/config.toml" = {
        source = config.lib.file.mkOutOfStoreSymlink "/run/secrets/attic/client-config";
        force = true;
      };
    };
}
