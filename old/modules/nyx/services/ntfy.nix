{
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://ntfy.olympus.moe";
      listen-http = ":1147";
    };
  };
}
