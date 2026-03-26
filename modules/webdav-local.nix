{
  services.davfs2.enable = true;

  systemd.mounts = [
    {
      enable = true;
      description = "Olympus Shared WebDAV mount";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      what = "http://172.17.100.1:3210/shared";
      where = "/media/olympus/shared";
      options = "uid=1000,gid=1000,file_mode=0664,dir_mode=2775,nofail";
      type = "davfs";
      mountConfig.TimeoutSec = 15;
    }
    {
      enable = true;
      description = "Olympus Private WebDAV mount";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      what = "http://172.17.100.1:3210/private";
      where = "/media/olympus/private";
      options = "uid=1000,gid=1000,file_mode=0664,dir_mode=2775,nofail";
      type = "davfs";
      mountConfig.TimeoutSec = 15;
    }
  ];
}
