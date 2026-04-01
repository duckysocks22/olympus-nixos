{ pkgs, ...}:
{
  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  programs.localsend = {
    enable = true;
    openFirewall = true;
  };
}
