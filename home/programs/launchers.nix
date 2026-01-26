{ pkgs, inputs, ...}:

{
  home.packages = [
    pkgs.steam
    pkgs.prismlauncher
    inputs.elysia.packages.x86_64-linux.default
  ];
}
