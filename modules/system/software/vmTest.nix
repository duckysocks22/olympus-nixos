{ inputs, self, ... }:
{
  flake.nixosModules.vmTest =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      environment.systemPackages = with pkgs; [ vm-test ];

      virtualisation.vmVariantWithDisko = {
        services.openssh = {
          enable = true;
          openFirewall = true;
          settings = {
            PasswordAuthentication = false;
            KbdInteractiveAuthentication = false;
            PermitRootLogin = lib.mkForce "prohibit-password";
          };
        };

        users.users = {
          root.openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJcAXHlW7WhNVvoU5H6q7BZDu09Tnd60P8QDJVhpbSiJ foxtrot@circe-nixos"
          ];
          # Only touch 'foxtrot' where the host actually declares it, otherwise this
          # stub user fails the isNormalUser/group assertions on the deck hosts.
        }
        // lib.optionalAttrs (config.users.users ? foxtrot) {
          foxtrot.hashedPasswordFile = lib.mkForce null;
        };

        virtualisation = {
          memorySize = 4096;
          cores = 4;
          forwardPorts = map (port: {
            from = "host";
            host.address = "127.0.0.1";
            host.port = port;
            guest.port = 22;
          }) (lib.range 2222 2231);
        };

        boot.kernelParams = [ "console=ttyS0" ];

        environment.systemPackages = [ pkgs.grim ];

        environment.sessionVariables = {
          LIBGL_ALWAYS_SOFTWARE = lib.mkDefault "1";
          MESA_LOADER_DRIVER_OVERRIDE = lib.mkDefault "kms_swrast";
        };

        systemd.services.sops-install-secrets.enable = lib.mkForce false;
        systemd.services.sops-install-secrets-for-users.enable = lib.mkForce false;
      };
    };
}
