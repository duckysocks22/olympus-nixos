{ config, lib, ... }:
{
  services.immich = {
    enable = true;
    host = "127.0.0.1";
    port = 2283;
    openFirewall = true;
    environment.IMMICH_LOG_LEVEL = "warn";

    accelerationDevices = [ "/dev/dri/renderD128" ];

    settings = {
      backup = {
        database = {
          enabled = true;
          cronExpression = "0 02 * * *";
          keepLastAmount = 14;
        };
      };
      machineLearning = {
        enabled = true;
        urls = [ "http://localhost:3004" ];
        ocr = {
          enabled = true;
          minDetectionScore = 0.5;
          minRecognitionScore = 0.8;
        };
        facialRecognition = {
          enabled = true;
          maxDistance = 0.5;
          minFaces = 3;
          minScore = 0.7;
        };
      };
      map = {
        enabled = true;
        darkStyle = "https://tiles.immich.cloud/v1/style/dark.json";
        lightStyle = "https://tiles.immich.cloud/v1/style/light.json";
      };
      nightlyTasks = {
        clusterNewFaces = true;
        databaseCleanup = true;
        generateMemories = true;
        missingThumbnails = true;
        startTime = "04:00";
        syncQuotaUsage = true;
      };
    };

    machine-learning = {
      enable = true;
      environment = {
        IMMICH_PORT = lib.mkForce "3004";
        MACHINE_LEARNING_CACHE_FOLDER = lib.mkForce "/media/hdd1/media/immich/machine-learning/cache";
        MACHINE_LEARNING_WORKERS = lib.mkForce "2";
      };
    };

    redis = {
      enable = true;
    };

    mediaLocation = "/media/hdd1/media/immich/";
    secretsFile = "${config.sops.secrets."immich/secrets".path}";
  };
}
