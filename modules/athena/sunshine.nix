{ ... }:
{
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };

  networking.firewall.allowedTCPPorts = [ 
    47984
    47989
    47990
    48010
  ];

  users.users.foxtrot = {
    extraGroups = [ "uinput" ];
  };
}
