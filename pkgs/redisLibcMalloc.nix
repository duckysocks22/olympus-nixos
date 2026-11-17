{ ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.redis-libc-malloc = pkgs.redis.overrideAttrs (prevAttrs: {
        makeFlags = prevAttrs.makeFlags ++ [ "MALLOC=libc" ];
      });
    };
}
