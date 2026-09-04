{ config, ... }:
{
  users.users.serena = {
    description = "Write-access to samba media shares";
    # Add this user to a group with permission to access the expected files
    extraGroups = [ "users" ];
    # Password can be set in clear text with a literal string or from a file.
    # Using sops-nix we can use the same file so that the system user and samba
    # user share the same credential (if desired).
    hashedPasswordFile = config.sops.secrets."users/server".path;
    isNormalUser = true;
  };

  system.activationScripts = {
    # The "init_smbpasswd" script name is arbitrary, but a useful label for tracking
    # failed scripts in the build output. An absolute path to smbpasswd is necessary
    # as it is not in $PATH in the activation script's environment. The password
    # is repeated twice with newline characters as smbpasswd requires a password
    # confirmation even in non-interactive mode where input is piped in through stdin.
    init_smbpasswd.text = ''
      /run/current-system/sw/bin/printf "$(/run/current-system/sw/bin/cat ${
        config.sops.secrets."samba-nyx/serena".path
      })\n$(/run/current-system/sw/bin/cat ${
        config.sops.secrets."samba-nyx/serena".path
      })\n" | /run/current-system/sw/bin/smbpasswd -sa serena
    '';
  };
}
