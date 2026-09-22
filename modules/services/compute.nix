{ inputs, self, ... }: {
  flake.nixosModules.compute = { inputs, ... }: {
    imports = [
      inputs.self.nixosModules.llama-cpp
    ];
  };

  flake.nixosModules.llama-cpp = { pkgs, pkgs-unstable, lib, config, ... }: let
    llama-cpp-prism = (pkgs-unstable.llama-cpp.override { cudaSupport = true; }).overrideDerivation (old: {
      version = "0.4.1-prism-b10709";
      src = pkgs.fetchFromGitHub {
        owner = "PrismML-Eng";
        repo = "llama.cpp";
        rev = "9a9394a895b96003ca842a6041cb28ac49a108f7";
        hash = "sha256-KDecY+v9S/193mLGse5EsJPugZR1wxWzOlOU7GuMd5Y=";
      };
    });
    models = {
      ornith = "${pkgs.fetchurl {
        url = "https://huggingface.co/bartowski/Ornith-1.5-9B-GGUF/resolve/main/Ornith-1.5-9B-IQ4_XS.gguf";
        hash = "sha256-lEruzScU0+ULaSkqP2w+OdBbBYZw8gKHRoy8R066P7k=";
      }}";
      gemma = "${pkgs.fetchurl {
        url = " https://huggingface.co/unsloth/gemma-4-12B-it-qat-GGUF/resolve/main/gemma-4-12B-it-qat-UD-Q4_K_XL.gguf";
        hash = lib.fakeHash;
      }}";
      bonsai = "${pkgs.fetchurl {
        url = "https://huggingface.co/prism-ml/Bonsai-27B-gguf/resolve/f10afb355f104535e3e3e98cf7ab7795c72bd292/Bonsai-27B-Q1_0.gguf";
        hash = "sha256-F++ELkdFDK646qPr+7q10vIni2K3m+EHmF+2mi+BmqA=";
      }}";
    };
  in {
    services.llama-cpp = {
      enable = true;
      package = llama-cpp-prism;
      host = "::";
      port = 5387;
      modelsDir = "/var/lib/llama-cpp-models";
      extraFlags = [
        "--no-models-autoload"
        "--api-key-file" "${config.sops.secrets."llama-cpp/api-key".path}"
        "--fit" "on"
        "--fit-target" "1600"
        "-c" "65536"
        "--cache-type-k" "q8_0"
        "--cache-type-v" "q8_0"
        "--jinja"
        "--reasoning" "off"
      ];
    };
    networking.firewall.allowedTCPPorts = [ 5387 ];
    systemd.tmpfiles.rules = [
      "d /var/lib/llama-cpp-models 0755 - - -"
      "C /var/lib/llama-cpp-models/Bonsai-27B-Q1_0.gguf 0644 - - - ${models.bonsai}"
    ];
    systemd.services.llama-cpp = {
      after = [ "systemd-tmpfiles-resetup.service" ];
      serviceConfig.CPUWeight = 20;
    };
  };
}
