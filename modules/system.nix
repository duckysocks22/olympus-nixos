{ pkgs, ...}:
{
  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;
  services.tuned.enable = true;
  services.upower.enable = true;
  programs.zsh.enable = true;

  environment.systemPackages = [
    pkgs.gptfdisk
    pkgs.gparted
    pkgs.xfsprogs
    pkgs.cifs-utils
    pkgs.nix-prefetch-git
    #pkgs.neovim
  ];
}
