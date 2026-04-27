{ pkgs, ... }:
{

  environment.systemPackages = with pkgs; [
    python312Packages.yt-dlp
  ];

  services.cron = {
    enable = true;
    systemCronJobs = [
      "0 3 */1 * *      server          yt-dlp -P /media/hdd1/audio/podcasts/Rotten_Mango/ -x --audio-format flac --audio-quality 0 --sponsorblock-remove default --embed-thumbnail --download-archive /media/hdd1/audio/podcasts/Rotten_Mango/archive.txt https://www.youtube.com/watch?v=-Sd9LX3aGFw&list=PLsDkDDndB1qsQToK8Ec0E0F8x6iLHWv5O"
      "0 3 */1 * *      server          yt-dlp -P /meedia/hdd1/audio/podcasts/Financial_Audit/ -x --audio-format flac --audio-quality 0 --sponsorblock-remove default --embed-thumbnail --download-archive /media/hdd1/audio/podcasts/Financial_Audit/archive.txt https://www.youtube.com/watch?v=8u7HqZJQHDM&list=PLzJVLNWKVr6ksDjycE7NpSptOlcaEP-jQ"
      "0 3 */1 * *      server          yt-dlp -P /media/hdd1/audio/podcasts/The_WAN_Show/ -x --audio-format flac --audio-quality 0 --sponsorblock-remove default --embed-thumbnail --download-archive /media/hdd1/audio/podcasts/The_WAN_Show/archive.txt https://www.youtube.com/watch?v=dm6aRONewxk&list=PL8mG-RkN2uTw7PhlnAr4pZZz2QubIbujH&index=1"
    ];
  };
}
