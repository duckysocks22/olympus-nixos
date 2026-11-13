{ inputs, ... }:
{
  flake.nixosModules.buildHost =
    {
      pkgs,
      ...
    }:
    let
      nixServeCommand = "restrict,command=\"/run/current-system/sw/bin/nix-store --serve --write\" ";
      nixServeKey = key: nixServeCommand + key;
    in
    {
      users.users.remotebuild = {
        isSystemUser = true;
        shell = pkgs.bashInteractive;
        group = "remotebuild";
        extraGroups = [ "nixbld" ];
        openssh.authorizedKeys.keys = [
          (nixServeKey "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPBfBQcP+cY9wRJnjOcVRJHK+GScY0J4WqRvNQNflLAA remotebuild@dionysus-nixos")
          (nixServeKey "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILowFk5QVcwetY3AHQaNTBw2rtUXUm+T65s0PTq0KWjf remotebuild@ariadne-nixos")
          (nixServeKey "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGR9cfncJ8YliZZ6RXd1oEgnqKBmldZ9XTyFG3pHUj5i remotebuild@aether-nixos")
          (nixServeKey "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGtfsezbfyGE2hzH8Crp9ve8z6uypz7g1//sOLF9lP+j remotebuild@circe-nixos")
        ];
      };

      users.groups.remotebuild = { };

      nix.settings.trusted-users = [ "remotebuild" ];
    };
}
