{ pkgs, ... }:
{
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
    host = "0.0.0.0";
    port = 11434;
    openFirewall = true;
    models = "/media/hdd1/ai/models";
    loadModels = [ "qwen3.5:4b" ];
    syncModels = false;
    acceleration = "cuda";
  };

  services.open-webui = {
    enable = true;
    port = 11435;
  };
}
