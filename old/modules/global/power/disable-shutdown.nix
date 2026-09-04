{
  config = {
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        polkit.log("action=" + action);
        polkit.log("subject=" + subject);
        if (
          action.id == "org.freedesktop.login1.halt" ||
          action.id == "org.freedesktop.login1.halt-ignore-inhibit" ||
          action.id == "org.freedesktop.login1.halt-multiple-sessions" ||
          action.id == "org.freedesktop.login1.hibernate" ||
          action.id == "org.freedesktop.login1.hibernate-ignore-inhibit" ||
          action.id == "org.freedesktop.login1.hibernate-multiple-sessions" ||
          action.id == "org.freedesktop.login1.inhibit-block-idle" ||
          action.id == "org.freedesktop.login1.inhibit-block-shutdown" ||
          action.id == "org.freedesktop.login1.inhibit-block-sleep" ||
          action.id == "org.freedesktop.login1.inhibit-handle-hibernate-key" ||
          action.id == "org.freedesktop.login1.inhibit-handle-lid-switch" ||
          action.id == "org.freedesktop.login1.inhibit-handle-power-key" ||
          action.id == "org.freedesktop.login1.inhibit-handle-reboot-key" ||
          action.id == "org.freedesktop.login1.inhibit-handle-suspend-key" ||
          action.id == "org.freedesktop.login1.power-off" ||
          action.id == "org.freedesktop.login1.power-off-ignore-inhibit" ||
          action.id == "org.freedesktop.login1.power-off-multiple-sessions" ||
          action.id == "org.freedesktop.login1.reboot" ||
          action.id == "org.freedesktop.login1.reboot-ignore-inhibit" ||
          action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
          action.id == "org.freedesktop.login1.set-reboot-parameter" ||
          action.id == "org.freedesktop.login1.set-reboot-to-boot-loader-entry" ||
          action.id == "org.freedesktop.login1.set-reboot-to-boot-loader-menu" ||
          action.id == "org.freedesktop.login1.set-reboot-to-firmware-setup" ||
          action.id == "org.freedesktop.login1.set-self-linger" ||
          action.id == "org.freedesktop.login1.set-user-linger" ||
          action.id == "org.freedesktop.login1.set-wall-message" ||
          action.id == "org.freedesktop.login1.suspend" ||
          action.id == "org.freedesktop.login1.suspend-ignore-inhibit" ||
          action.id == "org.freedesktop.login1.suspend-multiple-sessions"
        ) {
          return subject.active ? polkit.Result.AUTH_ADMIN : polkit.Result.NO;
        };
      });
    '';
  };
}
