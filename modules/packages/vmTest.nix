{ ... }: {
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
        text = builtins.readFile ../../assets/vm-test/vm-test.sh;
      };
    };
}
