final: prev: {
  ffmpeg-tdarr = prev.ffmpeg.override {
    nv-codec-headers-12 = prev.nv-codec-headers-12.overrideAttrs (_: {
      version = "12.2.72.0";
      src = prev.fetchgit {
        url = "https://git.videolan.org/git/ffmpeg/nv-codec-headers.git";
        rev = "157becbf51c8b813425572b75c06c370bd43d8fd";
        sha256 = "1dk13wjg56ddb9g0653fwx3n0h64xs7n8m5ys696adrhhgx77pym";
      };
    });
  };

  python3 = prev.python3.override {
    packageOverrides = _: pprev: {
      aiocache = pprev.aiocache.overrideAttrs (_: {
        doCheck = false;
      });
    };
  };
  python3Packages = final.python3.pkgs;
}
