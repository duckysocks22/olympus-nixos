{ inputs, ... }: {
  perSystem =
    { pkgs, ... }:
    {
      packages.vm-test = pkgs.writeShellApplication {
        name = "vm-test";
        runtimeInputs = with pkgs; [
          coreutils
          git
          iproute2
          netpbm
          nix
          openssh
          procps
          socat
          util-linux
        ];
        text = builtins.readFile "${
          inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.assets
        }/share/assets/vm-test/vm-test.sh";
      };
    };
}
