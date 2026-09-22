{ inputs, self, ... }: {
  flake.nixosModules.compute = { inputs, ... }: {
    imports = [
      inputs.self.nixosModules.llama-cpp
    ];
  };

  flake.nixosModules.llama-cpp = { pkgs, lib, config, ... }: let
    models = {
      ornith = "${pkgs.fetchurl {
        url = "https://huggingface.co/bartowski/Ornith-1.5-9B-GGUF/resolve/main/Ornith-1.5-9B-IQ4_XS.gguf";
        hash = "sha256-lEruzScU0+ULaSkqP2w+OdBbBYZw8gKHRoy8R066P7k=";
      }}";
      gemma = "${pkgs.fetchurl {
        url = " https://huggingface.co/unsloth/gemma-4-12B-it-qat-GGUF/resolve/main/gemma-4-12B-it-qat-UD-Q4_K_XL.gguf";
        hash = lib.fakeHash;
      }}";
    };
  in {
    services.llama-cpp = {
      enable = true;
      package = pkgs.llama-cpp.override { cudaSupport = true; };
      host = "::";
      port = 5387;
      modelsDir = "/var/lib/llama-cpp-models";
      extraFlags = [
        "--no-models-autoload"
        "--api-key-file" "${config.sops.secrets."llama-cpp/api-key".path}"
        "--fit" "on"
        "--fit-target" "1600"
        "-c" "8192"
        "--cache-type-k" "q8_0"
        "--cache-type-v" "q8_0"
        "--jinja"
        "--reasoning" "off"
      ];
    };
    networking.firewall.allowedTCPPorts = [ 5387 ];
    systemd.tmpfiles.rules = [
      "d /var/lib/llama-cpp-models 0755 - - -"
      "C /var/lib/llama-cpp-models/Ornith-1.5-9B-IQ4_XS.gguf 0644 - - - ${models.ornith}"
    ];
    systemd.services.llama-cpp = {
      after = [ "systemd-tmpfiles-resetup.service" ];
      serviceConfig.CPUWeight = 20;
    };
  };
}
