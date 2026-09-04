{ inputs, self, ... }:
{
  flake.homeModules.niri = { inputs, pkgs, self, ... }: {
    imports = [
      self.homeModules.dms
      self.homeModules.cursors
      inputs.niri.homeModules.config
    ];

    programs.niri = {
      settings = {
        outputs = {
          "PNP(AOC) CU34G2XP 1Q1R9UA004091" = {
            mode = { width = 3440; height = 1440; refreash = 180.0; };
            position = { x = 0; y = -0; };
            scale = 1.1;
            variable-refresh-rate = "on-demand";
            focus-at-startup = true;
          };
          "Acer Technologies Acer XFA240 0x91001AB2" = {
            mode = { width = 1920; height = 1080; refresh = 119.982; };
            position = { x = 1920; y = 200; };
            variable-refresh-rate = "on-demand";
          };
          DP-1 = {
            mode = { width = 3840; height = 2160; refresh = 120; };
            enable = false;
          };
        };
        binds = {
          # -- System & Overview ---
          "Mod+D" = { action.spawn = [ "niri" "msg" "action" "toggle-overview" ]; };
          "Mod+Tab" = { repeat = false; action.toggle-overview = { }; };
          "Mod+Shift+Slash".action.show-hotkey-overlay = { };

          # --- Application Launchers ---
          "Mod+Q" = { hotkey-overlay = { title = "Open Terminal"; }; action.spawn = "kitty"; };
          "Mod+R" = { hotkey-overlay = { title = "Application Launcher"; }; action.spawn = [ "dms" "ipc" "call" "launcher" "toggle" ]; };
          "Mod+V" = { hotkey-overlay = { title = "Clipboard Manager"; }; action.spawn = [ "dms" "ipc" "call" "spotlight" "toggle" ]; };
          "Mod+M" = { hotkey-overlay = { title = "Task Manager"; }; action.spawn = [ "dms" "ipc" "call" "processlist" "toggle" ]; };
          "Mod+Comma" = { hotkey-overlay = { title = "Settings"; }; action.spawn = [ "dms" "ipc" "call" "settings" "toggle" ]; };
          "Mod+Y" = { hotkey-overlay = { title = "Browse Wallpapers"; }; action.spawn = [ "dms" "ipc" "call" "dankdash" "wallpaper" ]; };
          "Mod+N" = { hotkey-overlay = { title = "Notification Center"; }; action.spawn = [ "dms" "ipc" "call" "notifications" "toggle" ]; };
          "Mod+Shift+N" = { hotkey-overlay = { title = "Notepad"; }; action.spawn = [ "dms" "ipc" "call" "notepad" "toggle" ]; };
          "Mod+E" = { hotkey-overlay = { title = "Open Thunar"; }; action.spawn = "dolphin"; };

          # --- Security ---
          "Mod+L" = { hotkey-overlay = { title = "Lock Screen"; }; action.spawn = [ "dms" "ipc" "call" "lock" "lock" ]; };
          "Mod+Shift+E".action.quit = { };
          "Ctrl+Alt+Delete" = { hotkey-overlay = { title = "Task Manager"; }; action.spawn = [ "dms" "ipc" "call" "processlist" "toggle" ]; };

          # --- Audio Controls ---
          "XF86AudioRaiseVolume" = { allow-when-locked = true; action.spawn = [ "dms" "ipc" "call" "audio" "increment" "3" ]; };
          "XF86AudioLowerVolume" = { allow-when-locked = true; action.spawn = [ "dms" "ipc" "call" "audio" "decrement" "3" ]; };
          "XF86AudioMute" = { allow-when-locked = true; action.spawn = [ "dms" "ipc" "call" "audio" "mute" ]; };
          "XF86AudioMicMute" = { allow-when-locked = true; action.spawn = [ "dms" "ipc" "call" "audio" "micmute" ]; };
          "XF86KbdBrightnessUp" = { allow-when-locked = true; action.spawn = [ "kbdbrite.sh" "up" ]; };
          "XF86KbdBrightnessDown" = { allow-when-locked = true; action.spawn = [ "kbdbrite.sh" "down" ]; };

          # --- Brightness ---
          "XF86MonBrightnessUp" = { allow-when-locked = true; action.spawn = [ "dms" "ipc" "call" "brightness" "increment" "5" "" ]; };
          "XF86MonBrightnessDown" = { allow-when-locked = true; action.spawn = [ "dms" "ipc" "call" "brightness" "decrement" "5" "" ]; };

          # --- Window Management ---
          "Mod+C" = { repeat = false; action.close-window = { }; };
          "Mod+F".action.maximize-column = { };
          "Mod+Shift+F".action.fullscreen-window = { };
          "Mod+Shift+T".action.toggle-window-floating = { };
          "Mod+Shift+V".action.switch-focus-between-floating-and-tiling = { };
          "Mod+W".action.toggle-column-tabbed-display = { };

          # --- Focus Navigation ---
          "Mod+Left".action.focus-column-left = { };
          "Mod+Down".action.focus-window-down = { };
          "Mod+Up".action.focus-window-up = { };
          "Mod+Right".action.focus-column-right = { };
          "Mod+H".action.focus-column-left = { };
          "Mod+J".action.focus-window-down = { };
          "Mod+K".action.focus-window-up = { };

          # --- Window Movement ---
          "Mod+Shift+Left".action.move-column-left = { };
          "Mod+Shift+Down".action.move-window-down = { };
          "Mod+Shift+Up".action.move-window-up = { };
          "Mod+Shift+Right".action.move-column-right = { };
          "Mod+Shift+H".action.move-column-left = { };
          "Mod+Shift+J".action.move-window-down = { };
          "Mod+Shift+K".action.move-window-up = { };
          "Mod+Shift+L".action.move-column-right = { };

          # --- Column Navigation ---
          "Mod+Home".action.focus-column-first = { };
          "Mod+End".action.focus-column-last = { };
          "Mod+Ctrl+Home".action.move-column-to-first = { };
          "Mod+Ctrl+End".action.move-column-to-last = { };

          # --- Monitor Navigation ---
          "Mod+Ctrl+Left".action.focus-monitor-left = { };
          "Mod+Ctrl+Right".action.focus-monitor-right = { };
          "Mod+Ctrl+H".action.focus-monitor-left = { };
          "Mod+Ctrl+J".action.focus-monitor-down = { };
          "Mod+Ctrl+K".action.focus-monitor-up = { };
          "Mod+Ctrl+L".action.focus-monitor-right = { };

          # --- Move to Monitor ---
          "Mod+Shift+Ctrl+Left".action.move-column-to-monitor-left = { };
          "Mod+Shift+Ctrl+Down".action.move-column-to-monitor-down = { };
          "Mod+Shift+Ctrl+Up".action.move-column-to-monitor-up = { };
          "Mod+Shift+Ctrl+Right".action.move-column-to-monitor-right = { };
          "Mod+Shift+Ctrl+H".action.move-column-to-monitor-left = { };
          "Mod+Shift+Ctrl+J".action.move-column-to-monitor-down = { };
          "Mod+Shift+Ctrl+K".action.move-column-to-monitor-up = { };
          "Mod+Shift+Ctrl+L".action.move-column-to-monitor-right = { };

          # --- Workspace Navigation ---
          "Mod+Page_Down".action.focus-workspace-down = { };
          "Mod+Page_Up".action.focus-workspace-up = { };
          "Mod+U".action.focus-workspace-down = { };
          "Mod+I".action.focus-workspace-up = { };
          "Mod+Ctrl+Down".action.move-column-to-workspace-down = { };
          "Mod+Ctrl+Up".action.move-column-to-workspace-up = { };
          "Mod+Ctrl+U".action.move-column-to-workspace-down = { };
          "Mod+Ctrl+I".action.move-column-to-workspace-up = { };

          # --- Move Workspaces ---
          "Mod+Shift+Page_Down".action.move-workspace-down = { };
          "Mod+Shift+Page_Up".action.move-workspace-up = { };
          "Mod+Shift+U".action.move-workspace-down = { };
          "Mod+Shift+I".action.move-workspace-up = { };

          # --- Mouse Wheel Navigation ---
          "Mod+WheelScrollDown".action.focus-column-right = { };
          "Mod+WheelScrollUp".action.focus-column-left = { };
          "Mod+Ctrl+WheelScrollDown" = { cooldown-ms = 150; action.focus-workspace-down = { }; };
          "Mod+Ctrl+WheelScrollUp" = { cooldown-ms = 150; action.focus-workspace-up = { }; };
          "Mod+WheelScrollRight".action.focus-column-right = { };
          "Mod+WheelScrollLeft".action.focus-column-left = { };
          "Mod+Ctrl+WheelScrollRight".action.move-column-right = { };
          "Mod+Ctrl+WheelScrollLeft".action.move-column-left = { };
          "Mod+Shift+WheelScrollDown".action.focus-column-right = { };
          "Mod+Shift+WheelScrollUp".action.focus-column-left = { };
          "Mod+Ctrl+Shift+WheelScrollDown".action.move-column-right = { };
          "Mod+Ctrl+Shift+WheelScrollUp".action.move-column-left = { };

          # --- Numbered Workspaces ---
          "Mod+1".action.focus-workspace = 1;
          "Mod+2".action.focus-workspace = 2;
          "Mod+3".action.focus-workspace = 3;
          "Mod+4".action.focus-workspace = 4;
          "Mod+5".action.focus-workspace = 5;
          "Mod+6".action.focus-workspace = 6;
          "Mod+7".action.focus-workspace = 7;
          "Mod+8".action.focus-workspace = 8;
          "Mod+9".action.focus-workspace = 9;

          # --- Move to Numbered Workspaces ---
          "Mod+Shift+1".action.move-column-to-workspace = 1;
          "Mod+Shift+2".action.move-column-to-workspace = 2;
          "Mod+Shift+3".action.move-column-to-workspace = 3;
          "Mod+Shift+4".action.move-column-to-workspace = 4;
          "Mod+Shift+5".action.move-column-to-workspace = 5;
          "Mod+Shift+6".action.move-column-to-workspace = 6;
          "Mod+Shift+7".action.move-column-to-workspace = 7;
          "Mod+Shift+8".action.move-column-to-workspace = 8;
          "Mod+Shift+9".action.move-column-to-workspace = 9;

          # --- Column Management ---
          "Mod+BracketLeft".action.consume-or-expel-window-left = { };
          "Mod+BracketRight".action.consume-or-expel-window-right = { };
          "Mod+Period".action.expel-window-from-column = { };

          # --- Sizing & Layout ---
          "Mod+Shift+R".action.switch-preset-window-height = { };
          "Mod+Ctrl+R".action.reset-window-height = { };
          "Mod+Ctrl+F".action.expand-column-to-available-width = { };
          "Mod+Ctrl+C".action.center-visible-columns = { };

          # --- Manual Sizing ---
          "Mod+Minus".action.set-column-width = "-10%";
          "Mod+Equal".action.set-column-width = "+10%";
          "Mod+Shift+Minus".action.set-window-height = "-10%";
          "Mod+Shift+Equal".action.set-window-height = "+10%";

          # --- Screenshots ---
          "XF86Launch1".action.screenshot = { };
          "Ctrl+XF86Launch1".action.screenshot-screen = { };
          "Alt+XF86Launch1".action.screenshot-window = { };
          "Print".action.screenshot = { };
          "Ctrl+Print".action.screenshot-screen = { };
          "Alt+Print".action.screenshot-window = { };
          "Mod+Shift+S".action.screenshot = { };

          # --- Screen Recording / System ---
          "F12".action.spawn = [ "pkill" "-SIGRTMIN+4" "-f" "gpu-screen-recorder" ];
          "Mod+Escape" = { allow-inhibiting = false; action.toggle-keyboard-shortcuts-inhibit = { }; };
          "Mod+Shift+P".action.power-off-monitors = { };
        };
      };
    };

    home.packages = with pkgs; [ niri dconf slurp libnotify xwayland-satellite ];

    gtk = {
      enable = true;
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
    };

    dconf = {
      enable = true;
      settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
        };
      };
    };

    services.polkit-gnome.enable = true;
  };

  flake.homeModules.dms = { inputs, pkgs, lib, ... }: {
    imports = [ inputs.dms.homeModules.dank-material-shell inputs.dms-plugin-registry.homeModules.default ];

    programs.dank-material-shell = {
      enable = true;
      systemd.enable = true;
      dgop.package = inputs.dgop.packages.${pkgs.stdenv.hostPlatform.system}.default;
      enableSystemMonitoring = true;
      enableVPN = false;
      enableDynamicTheming = true;
      enableAudioWavelength = false;
      enableCalendarEvents = false;
      enableClipboardPaste = true;

      plugins = {
        dankBatteryAlerts.enable = true;
        dms-screen-recorder = {
          src = pkgs.fetchFromGitHub {
            owner = "arqueon";
            repo = "dms-screen-recorder";
            rev = "v1.2.0";
            sha256 = "sha256-jkhrjgoLM2IGUgJUkoEGdsZVf9DIxY6j9X8Lh6rA05Y=";
          };
          enable = true;
        };
      };

      settings = {
        currentThemeName = "dynamic";
        currentThemeCategory = "dynamic";
        customThemeFile = "";
        registryThemeVariants = { };
        matugenScheme = "scheme-tonal-spot";
        runUserMatugenTemplates = true;
        matugenTargetMonitor = "";
        popupTransparency = 1;
        dockTransparency = 1;
        widgetBackgroundColor = "sch";
        widgetColorMode = "colorful";
        controlCenterTileColorMode = "primary";
        buttonColorMode = "primary";
        cornerRadius = 12;
        e24HourClock = true;
        showSeconds = false;
        padHours12Hour = false;
        useFahrenheit = false;
        windSpeedUnit = "kmh";
        nightModeEnabled = false;
        animationSpeed = 1;
        customAnimationDuration = 988;
        syncComponentAnimationSpeeds = true;
        popoutAnimationSpeed = 1;
        popoutCustomAnimationDuration = 150;
        modalAnimationSpeed = 1;
        modalCustomAnimationDuration = 150;
        enableRippleEffects = true;
        blurEnabled = false;
        blurForegroundLayers = true;
        blurLayerOutlineOpacity = 0.12;
        blurBorderColor = "outline";
        blurBorderCustomColor = "#ffffff";
        blurBorderOpacity = 0.35;
        wallpaperFillMode = "Fill";
        blurredWallpaperLayer = false;
        blurWallpaperOnOverview = true;
        showLauncherButton = true;
        showWorkspaceSwitcher = true;
        showFocusedWindow = true;
        showWeather = true;
        showMusic = true;
        showClipboard = true;
        showCpuUsage = true;
        showMemUsage = true;
        showCpuTemp = true;
        showGpuTemp = true;
        selectedGpuIndex = 0;
        enabledGpuPciIds = [ ];
        showSystemTray = true;
        systemTrayIconTintMode = "primary";
        systemTrayIconTintSaturation = 50;
        systemTrayIconTintStrength = 135;
        showClock = true;
        showNotificationButton = true;
        showBattery = true;
        showControlCenterButton = true;
        showCapsLockIndicator = true;
        controlCenterShowNetworkIcon = true;
        controlCenterShowBluetoothIcon = true;
        controlCenterShowAudioIcon = true;
        controlCenterShowAudioPercent = false;
        controlCenterShowVpnIcon = true;
        controlCenterShowBrightnessIcon = false;
        controlCenterShowBrightnessPercent = false;
        controlCenterShowMicIcon = false;
        controlCenterShowMicPercent = false;
        controlCenterShowBatteryIcon = false;
        controlCenterShowPrinterIcon = false;
        controlCenterShowScreenSharingIcon = true;
        showPrivacyButton = true;
        privacyShowMicIcon = false;
        privacyShowCameraIcon = false;
        privacyShowScreenShareIcon = false;
        controlCenterWidgets = [
          {
            id = "volumeSlider";
            enabled = true;
            width = 50;
          }
          {
            id = "brightnessSlider";
            enabled = true;
            width = 50;
          }
          {
            id = "wifi";
            enabled = true;
            width = 50;
          }
          {
            id = "bluetooth";
            enabled = true;
            width = 50;
          }
          {
            id = "audioOutput";
            enabled = true;
            width = 50;
          }
          {
            id = "audioInput";
            enabled = true;
            width = 50;
          }
          {
            id = "nightMode";
            enabled = true;
            width = 50;
          }
          {
            id = "darkMode";
            enabled = true;
            width = 50;
          }
        ];
        showWorkspaceIndex = false;
        showWorkspaceName = false;
        showWorkspacePadding = false;
        workspaceScrolling = false;
        showWorkspaceApps = false;
        workspaceDragReorder = true;
        maxWorkspaceIcons = 3;
        workspaceAppIconSizeOffset = 0;
        groupWorkspaceApps = true;
        workspaceFollowFocus = false;
        showOccupiedWorkspacesOnly = false;
        reverseScrolling = false;
        dwlShowAllTags = false;
        workspaceColorMode = "default";
        workspaceOccupiedColorMode = "none";
        workspaceUnfocusedColorMode = "default";
        workspaceUrgentColorMode = "default";
        workspaceFocusedBorderEnabled = false;
        workspaceFocusedBorderColor = "primary";
        workspaceFocusedBorderThickness = 2;
        workspaceNameIcons = { };
        waveProgressEnabled = true;
        scrollTitleEnabled = true;
        audioVisualizerEnabled = true;
        audioScrollMode = "volume";
        audioWheelScrollAmount = 5;
        clockCompactMode = false;
        focusedWindowCompactMode = false;
        runningAppsCompactMode = true;
        barMaxVisibleApps = 0;
        barMaxVisibleRunningApps = 0;
        barShowOverflowBadge = true;
        appsDockHideIndicators = false;
        appsDockColorizeActive = false;
        appsDockActiveColorMode = "primary";
        appsDockEnlargeOnHover = false;
        appsDockEnlargePercentage = 125;
        appsDockIconSizePercentage = 100;
        keyboardLayoutNameCompactMode = false;
        runningAppsCurrentWorkspace = true;
        runningAppsGroupByApp = false;
        runningAppsCurrentMonitor = false;
        appIdSubstitutions = [
          {
            pattern = "Spotify";
            replacement = "spotify";
            type = "exact";
          }
          {
            pattern = "beepertexts";
            replacement = "beeper";
            type = "exact";
          }
          {
            pattern = "home assistant desktop";
            replacement = "homeassistant-desktop";
            type = "exact";
          }
          {
            pattern = "com.transmissionbt.transmission";
            replacement = "transmission-gtk";
            type = "contains";
          }
          {
            pattern = "^steam_app_(\\d+)$";
            replacement = "steam_icon_$1";
            type = "regex";
          }
        ];
        centeringMode = "index";
        clockDateFormat = "";
        lockDateFormat = "";
        greeterRememberLastSession = true;
        greeterRememberLastUser = true;
        greeterEnableFprint = false;
        greeterEnableU2f = false;
        greeterWallpaperPath = "";
        mediaSize = 1;
        appLauncherViewMode = "list";
        spotlightModalViewMode = "list";
        browserPickerViewMode = "grid";
        browserUsageHistory = { };
        appPickerViewMode = "grid";
        filePickerUsageHistory = { };
        sortAppsAlphabetically = false;
        appLauncherGridColumns = 4;
        spotlightCloseNiriOverview = true;
        spotlightSectionViewModes = { };
        appDrawerSectionViewModes = { };
        niriOverviewOverlayEnabled = true;
        dankLauncherV2Size = "compact";
        dankLauncherV2BorderEnabled = false;
        dankLauncherV2BorderThickness = 2;
        dankLauncherV2BorderColor = "primary";
        dankLauncherV2ShowFooter = true;
        dankLauncherV2UnloadOnClose = false;
        useAutoLocation = false;
        weatherEnabled = true;
        networkPreference = "auto";
        iconTheme = "System Default";
        cursorSettings = {
          theme = "Bibata-Original-Ice";
          size = 25;
          niri = {
            hideWhenTyping = true;
            hideAfterInactiveMs = 2401;
          };
          hyprland = {
            hideOnKeyPress = false;
            hideOnTouch = false;
            inactiveTimeout = 0;
          };
          dwl = {
            cursorHideTimeout = 0;
          };
        };
        launcherLogoMode = "os";
        launcherLogoCustomPath = "";
        launcherLogoColorOverride = "surface";
        launcherLogoColorInvertOnMode = false;
        launcherLogoBrightness = 0.5;
        launcherLogoContrast = 1;
        launcherLogoSizeOffset = 0;
        fontFamily = "Inter Variable";
        monoFontFamily = "Fira Code";
        fontWeight = 400;
        fontScale = 1;
        notepadUseMonospace = true;
        notepadFontFamily = "";
        notepadFontSize = 14;
        notepadShowLineNumbers = false;
        adLastCustomTransparency = 0.7;
        soundsEnabled = true;
        useSystemSoundTheme = false;
        soundNewNotification = true;
        soundVolumeChanged = true;
        soundPluggedIn = true;
        acMonitorTimeout = 3600;
        acLockTimeout = 300;
        acSuspendTimeout = 0;
        acSuspendBehavior = 0;
        acProfileName = "";
        batteryMonitorTimeout = 600;
        batteryLockTimeout = 300;
        batterySuspendTimeout = 900;
        batterySuspendBehavior = 2;
        batteryProfileName = "";
        batteryChargeLimit = 100;
        lockBeforeSuspend = true;
        loginctlLockIntegration = true;
        fadeToLockEnabled = true;
        fadeToLockGracePeriod = 5;
        fadeToDpmsEnabled = true;
        fadeToDpmsGracePeriod = 5;
        launchPrefix = "";
        brightnessDevicePins = { };
        wifiNetworkPins = { };
        bluetoothDevicePins = { };
        audioInputDevicePins = { };
        audioOutputDevicePins = { };
        gtkThemingEnabled = false;
        qtThemingEnabled = false;
        syncModeWithPortal = true;
        terminalsAlwaysDark = true;
        muxType = "tmux";
        muxUseCustomCommand = false;
        muxCustomCommand = "";
        muxSessionFilter = "";
        runDmsMatugenTemplates = true;
        matugenTemplateGtk = true;
        matugenTemplateNiri = true;
        matugenTemplateHyprland = false;
        matugenTemplateMangowc = false;
        matugenTemplateQt5ct = true;
        matugenTemplateQt6ct = true;
        matugenTemplateFirefox = true;
        matugenTemplatePywalfox = false;
        matugenTemplateZenBrowser = false;
        matugenTemplateVesktop = true;
        matugenTemplateEquibop = false;
        matugenTemplateGhostty = false;
        matugenTemplateKitty = true;
        matugenTemplateFoot = false;
        matugenTemplateAlacritty = false;
        matugenTemplateNeovim = false;
        matugenTemplateWezterm = false;
        matugenTemplateDgop = true;
        matugenTemplateKcolorscheme = true;
        matugenTemplateVscode = true;
        matugenTemplateEmacs = false;
        matugenTemplateZed = false;
        showDock = false;
        dockAutoHide = false;
        dockSmartAutoHide = false;
        dockGroupByApp = false;
        dockOpenOnOverview = false;
        dockPosition = 1;
        dockSpacing = 4;
        dockBottomGap = 0;
        dockMargin = 0;
        dockIconSize = 40;
        dockIndicatorStyle = "circle";
        dockBorderEnabled = false;
        dockBorderColor = "surfaceText";
        dockBorderOpacity = 1;
        dockBorderThickness = 1;
        dockIsolateDisplays = false;
        dockLauncherEnabled = false;
        dockLauncherLogoMode = "apps";
        dockLauncherLogoCustomPath = "";
        dockLauncherLogoColorOverride = "";
        dockLauncherLogoSizeOffset = 0;
        dockLauncherLogoBrightness = 0.5;
        dockLauncherLogoContrast = 1;
        dockMaxVisibleApps = 0;
        dockMaxVisibleRunningApps = 0;
        dockShowOverflowBadge = true;
        notificationOverlayEnabled = false;
        notificationPopupShadowEnabled = true;
        notificationPopupPrivacyMode = true;
        modalDarkenBackground = true;
        lockScreenShowPowerActions = true;
        lockScreenShowSystemIcons = true;
        lockScreenShowTime = true;
        lockScreenShowDate = true;
        lockScreenShowProfileImage = true;
        lockScreenShowPasswordField = true;
        lockScreenShowMediaPlayer = true;
        lockScreenPowerOffMonitorsOnLock = true;
        lockAtStartup = false;
        enableFprint = false;
        maxFprintTries = 15;
        enableU2f = false;
        u2fMode = "or";
        lockScreenActiveMonitor = "all";
        lockScreenInactiveColor = "#000000";
        lockScreenNotificationMode = 0;
        hideBrightnessSlider = false;
        notificationTimeoutLow = 5000;
        notificationTimeoutNormal = 5000;
        notificationTimeoutCritical = 0;
        notificationCompactMode = true;
        notificationPopupPosition = 0;
        notificationAnimationSpeed = 1;
        notificationCustomAnimationDuration = 400;
        notificationHistoryEnabled = true;
        notificationHistoryMaxCount = 50;
        notificationHistoryMaxAgeDays = 1;
        notificationHistorySaveLow = false;
        notificationHistorySaveNormal = true;
        notificationHistorySaveCritical = true;
        notificationRules = [ ];
        osdAlwaysShowValue = false;
        osdPosition = 5;
        osdVolumeEnabled = true;
        osdMediaVolumeEnabled = true;
        osdMediaPlaybackEnabled = false;
        osdBrightnessEnabled = true;
        osdIdleInhibitorEnabled = true;
        osdMicMuteEnabled = true;
        osdCapsLockEnabled = true;
        osdPowerProfileEnabled = false;
        osdAudioOutputEnabled = true;
        powerActionConfirm = true;
        powerActionHoldDuration = 0.5;
        powerMenuActions = [
          "reboot"
          "logout"
          "poweroff"
          "lock"
          "suspend"
          "restart"
        ];
        powerMenuDefaultAction = "logout";
        powerMenuGridLayout = false;
        customPowerActionLock = "";
        customPowerActionLogout = "";
        customPowerActionSuspend = "";
        customPowerActionHibernate = "";
        customPowerActionReboot = "";
        customPowerActionPowerOff = "";
        updaterHideWidget = false;
        updaterUseCustomCommand = false;
        updaterCustomCommand = "";
        updaterTerminalAdditionalParams = "";
        displayNameMode = "system";
        screenPreferences = { };
        showOnLastDisplay = { };
        niriOutputSettings = { };
        hyprlandOutputSettings = { };
        displayProfiles = { };
        activeDisplayProfile = { };
        displayProfileAutoSelect = false;
        displayShowDisconnected = false;
        displaySnapToEdge = true;
        barConfigs = [
          {
            id = "default";
            name = "Main Bar";
            enabled = true;
            position = 0;
            screenPreferences = [
              "all"
            ];
            showOnLastDisplay = true;
            leftWidgets = [
              "launcherButton"
              "workspaceSwitcher"
              "focusedWindow"
            ];
            centerWidgets = [
              "music"
              "clock"
              "weather"
            ];
            rightWidgets = [
              "systemTray"
              "clipboard"
              "cpuUsage"
              "memUsage"
              "notificationButton"
              "battery"
              "controlCenterButton"
            ];
            spacing = 2;
            innerPadding = 1;
            parency = 1;
            widgetTransparency = 1;
            squareCorners = false;
            noBackground = false;
            gothCornersEnabled = false;
            gothCornerRadiusOverride = false;
            gothCornerRadiusValue = 12;
            borderEnabled = false;
            borderColor = "surfaceText";
            borderOpacity = 1;
            borderThickness = 1;
            fontScale = 1;
            autoHide = false;
            autoHideDelay = 250;
            openOnOverview = false;
            visible = true;
            popupGapsAuto = true;
            popupGapsManual = 4;
            widgetPadding = 10;
            widgetOutlineEnabled = false;
            shadowIntensity = 37;
            shadowOpacity = 35;
            shadowColorMode = "custom";
          }
        ];
        desktopClockEnabled = false;
        desktopClockStyle = "analog";
        desktopClockTransparency = 0.8;
        desktopClockColorMode = "primary";
        desktopClockCustomColor = {
          r = 1;
          g = 1;
          b = 1;
          a = 1;
          vSaturation = 0;
          hsvValue = 1;
          lSaturation = 0;
          hslLightness = 1;
          valid = true;
        };
        desktopClockShowDate = true;
        desktopClockShowAnalogNumbers = false;
        desktopClockShowAnalogSeconds = true;
        desktopClockHeight = 180;
        desktopClockDisplayPreferences = [
          "all"
        ];
        systemMonitorEnabled = false;
        systemMonitorShowHeader = true;
        systemMonitorTransparency = 0.8;
        systemMonitorColorMode = "primary";
        systemMonitorCustomColor = {
          r = 1;
          g = 1;
          b = 1;
          a = 1;
          vSaturation = 0;
          hsvValue = 1;
          lSaturation = 0;
          hslLightness = 1;
          valid = true;
        };
        systemMonitorShowCpu = true;
        systemMonitorShowCpuGraph = true;
        systemMonitorShowCpuTemp = true;
        systemMonitorShowGpuTemp = false;
        systemMonitorGpuPciId = "";
        systemMonitorShowMemory = true;
        systemMonitorShowMemoryGraph = true;
        systemMonitorShowNetwork = true;
        systemMonitorShowNetworkGraph = true;
        systemMonitorShowDisk = true;
        systemMonitorShowTopProcesses = false;
        systemMonitorTopProcessCount = 3;
        systemMonitorTopProcessSortBy = "cpu";
        systemMonitorGraphInterval = 60;
        systemMonitorLayoutMode = "auto";
        systemMonitorWidth = 320;
        systemMonitorHeight = 480;
        systemMonitorDisplayPreferences = [
          "all"
        ];
        systemMonitorVariants = [ ];
        desktopWidgetPositions = { };
        desktopWidgetGridSettings = { };
        desktopWidgetInstances = [ ];
        desktopWidgetGroups = [ ];
        builtInPluginSettings = {
          dms_settings_search = {
            trigger = "?";
          };
        };
        clipboardEnterToPaste = false;
        launcherPluginVisibility = { };
        launcherPluginOrder = [ ];
        configVersion = 5;
      };

      session = {
        isLightMode = false;
        doNotDisturb = false;
        wallpaperPath = ../assets/wallpapers/bafkreidxnbp4exjkrvd7vpfylv4bfz5n4w66wpnuodip5kkq3mguqwyixi.jpg;
        perMonitorWallpaper = false;
        monitorWallpapers = { };
        perModeWallpaper = false;
        wallpaperPathLight = "";
        wallpaperPathDark = "";
        monitorWallpapersLight = { };
        monitorWallpapersDark = { };
        monitorWallpaperFillModes = { };
        wallpaperTransition = "fade";
        includedTransitions = [
          "fade"
          "wipe"
          "disc"
          "stripes"
          "iris bloom"
          "pixelate"
          "portal"
        ];
        wallpaperCyclingEnabled = false;
        wallpaperCyclingMode = "interval";
        wallpaperCyclingInterval = 300;
        wallpaperCyclingTime = "06:00";
        monitorCyclingSettings = { };
        nightModeEnabled = true;
        nightModeTemperature = 5200;
        nightModeHighTemperature = 6500;
        nightModeAutoEnabled = false;
        nightModeAutoMode = "time";
        nightModeStartHour = 18;
        nightModeStartMinute = 0;
        nightModeEndHour = 6;
        nightModeEndMinute = 0;
        latitude = 0;
        longitude = 0;
        nightModeUseIPLocation = false;
        nightModeLocationProvider = "";
        themeModeAutoEnabled = false;
        themeModeAutoMode = "time";
        themeModeStartHour = 18;
        themeModeStartMinute = 0;
        themeModeEndHour = 6;
        themeModeEndMinute = 0;
        themeModeShareGammaSettings = true;
        weatherLocation = "New York, NY";
        weatherCoordinates = "40.7128,-74.0060";
        pinnedApps = [ ];
        barPinnedApps = [ ];
        dockLauncherPosition = 0;
        hiddenTrayIds = [ ];
        trayItemOrder = [ ];
        recentColors = [ ];
        showThirdPartyPlugins = false;
        launchPrefix = "";
        lastBrightnessDevice = "";
        brightnessExponentialDevices = { };
        brightnessUserSetValues = { };
        brightnessExponentValues = { };
        selectedGpuIndex = 0;
        nvidiaGpuTempEnabled = false;
        nonNvidiaGpuTempEnabled = false;
        enabledGpuPciIds = [ ];
        wifiDeviceOverride = "";
        weatherHourlyDetailed = true;
        hiddenApps = [ ];
        appOverrides = { };
        searchAppActions = true;
        vpnLastConnected = "";
        deviceMaxVolumes = { };
        hiddenOutputDeviceNames = [ ];
        hiddenInputDeviceNames = [ ];
        launcherLastMode = "all";
        appDrawerLastMode = "apps";
        niriOverviewLastMode = "apps";
        configVersion = 3;
      };
    };

    systemd.user.services.dms.Service = {
      MemoryMax = "12G";
      RestartSec = "5s";
    };

    systemd.user.services.dms.Unit.StartLimitIntervalSec = 0;
  };

  flake.homeModules.cursors = { pkgs, ... }: {
    home = {
      packages = [ ];
      pointerCursor = {
        gtk.enable = true;
        x11.enable = true;
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Ice";
        size = 14;
      };
    };
  };
}
