{ pkgs, inputs, ...}:

{
  home.packages = [
    pkgs.prismlauncher
    inputs.elysia.packages.x86_64-linux.default
    #inputs.agl.packages.x86_64-linux.default
    pkgs.xivlauncher
    (pkgs.olympus.override { celesteWrapper = "steam-run"; })
    pkgs.ludusavi
    pkgs.r2modman
    pkgs.heroic
  ];
}
