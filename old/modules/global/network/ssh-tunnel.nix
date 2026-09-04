{ ... }:
{
  services.autossh.sessions = [
    {
      name = "anthrophic-proxy";
      user = "foxtrot";
      monitoringPort = 0;
      extraArguments = "-N -D 1080 -i /home/foxtrot/.ssh/id_ed25519 -p 2222 tunnel@puppygirls.net";
    }
    {
      name = "steam-proxy";
      user = "foxtrot";
      monitoringPort = 0;
      extraArguments = "-N -D 1081 -i /home/foxtrot/.ssh/id_ed25519 -p 2222 -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes tunnel@puppygirls.net";
    }
  ];

  programs.proxychains = {
    enable = true;
    chain.type = "strict";
    proxyDNS = true;
    quietMode = true;
    proxies.anthropic-tunnel = {
      enable = true;
      type = "socks5";
      host = "127.0.0.1";
      port = 1080;
    };
  };

  programs.zsh.shellAliases = {
    claude = "proxychains4 claude";
  };
}
