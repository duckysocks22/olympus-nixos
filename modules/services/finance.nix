{ inputs, self, ... }: {
  flake.nixosModules.finance-summary =
    { config, lib, pkgs, util, ... }:
    let
      summaryApp = pkgs.buildNpmPackage {
        pname = "finance-summary";
        version = "0.1.0";
        src = ../../assets/finance-summary;
        nodejs = pkgs.nodejs_22;
        npmDepsHash = "sha256-v6TFZpFD4G7hTdd1jyjeL6EK6YX6jdpsGO0o9Jxe9+U=";
        dontNpmBuild = true;
        meta.mainProgram = "finance-summary";
      };
      unit = util.functions.mkSimpleService {
        description = "Monthly finance summary (Actual to llama-cpp)";
        ExecStart = lib.getExe summaryApp;
        type = "oneshot";
      };
    in
    {
      systemd.services.finance-summary = unit // {
        wantedBy = [ ];
        environment = {
          ACTUAL_SERVER_URL = "http://localhost:5006";
          ACTUAL_CACHE_DIR = "/var/lib/finance-summary/actual-cache";
          LLAMA_BASE_URL = "http://localhost:5387/v1";
          LLAMA_API_KEY_FILE = config.sops.secrets."llama-cpp/api-key".path;
        };
        serviceConfig = unit.serviceConfig // {
          Restart = "no";
          StateDirectory = "finance-summary";
          EnvironmentFile = config.sops.secrets."finance-summary/env".path;
        };
      };

      systemd.timers.finance-summary = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*-*-01 06:00";
          Persistent = true;
        };
      };
    };
}
