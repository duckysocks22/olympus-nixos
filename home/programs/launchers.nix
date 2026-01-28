{ pkgs, inputs, ...}:

{
  home.packages = [
    pkgs.prismlauncher
    inputs.elysia.packages.x86_64-linux.default
  ];
}
