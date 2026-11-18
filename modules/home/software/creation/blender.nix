{ inputs, ... }:
{
  flake.homeModules.blender =
    {
      pkgs,
      ...
    }:
    let
      blender-hip = (
        pkgs.blender.override {
          config.rocmSupport = true;
          config.cudaSupport = false;
        }
      );
    in
    {
      home.packages = [
        (blender-hip.withPackages (ps: [
          ps.pyserial
          ps.fs
          ps.yq
        ]))
      ];
    };
}
