{ inputs, self, ... }:
{
  flake.nixosModules.diskoVM =
    {
      ...
    }:
    {
      virtualisation.vmVariantWithDisko = {
        users.users.root.initialPassword = "root";

        boot.initrd = {
          availableKernelModules = [ "virtio_gpu" ];
          secrets."/tmp/luks-vm.key" = builtins.toFile "luks-vm.key" "disko";

          luks.devices = {
            "crypted".keyFile = "/tmp/luks-vm.key";
            "crypted-swap".keyFile = "/tmp/luks-vm.key";
          };
        };
      };
    };
}
