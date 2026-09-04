{ pkgs, ... }:
{

  environment.systemPackages = with pkgs; [
    python312Packages.yt-dlp
  ];
}
