{ pkgs, config, lib, ...}:
{
  services.frigate = {
    enable = true;
    hostname = "frigate.olympus.local";
    settings = {
      mqtt.enabled = false;

      record = {
        enabled = true;
        retain = {
          days = 2;
          mode = "all";
        };
      };
      
      auth = {
      };

      ffmpeg.hwaccel_args = "preset-nvidia";

      cameras."entry-way" = {
        ffmpeg.inputs = [ 
          {
            path = "rtsp://127.0.0.1:8554/entry-way-main";
            input_args = [ "-rtsp_transport" "tcp" ];
            roles = [ "record" ];
          } 
          {
            path = "rtsp://127.0.0.1:8554/entry-way-sub";
            input_args = [ "-rtsp_transport" "tcp" ];
            roles = [ "detect" ];
          }
        ];
        detect = {
          fps = 5;
          width = 800;
          height = 600;
        };
      };
    };
  };

  systemd.services.frigate = {
    environment.LIBVA_DRIVER_NAME = "nvidia";
    serviceConfig = {
      SupplementaryGroups = ["render" "video"];
      AmbientCapabilities = "CAP_PERFMON";
    };
  };

  services.go2rtc = {
    enable = true;
    settings = {
      streams = {
        entry-way-main = "rtsp://foxtrot:password@10.0.150.1/stream1";
        entry-way-sub = "rtsp://foxtrot:password@10.0.150.1/stream1";
      };
      rtsp = {
        listen = ":8554";
      };
      api = {
        username = "foxtrot";
        password = "admin";
      };
    };
  };
}
