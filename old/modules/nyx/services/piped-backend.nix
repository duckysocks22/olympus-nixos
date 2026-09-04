{
  imports = [ ../../packages/piped-backend/service.nix ];

  services.piped-backend = {
    enable = true;
    settings = {

    };
  };
}
