{ inputs, pkgs, ...}:
{
  environment.systemPackages = [
    inputs.netwatch.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  security.wrappers = {
      netwatch = {
        owner = "root";
        group = "root";
        capabilities = "cap_net_raw+ep";
        source = "${inputs.netwatch.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/netwatch";
      };
  };
}
