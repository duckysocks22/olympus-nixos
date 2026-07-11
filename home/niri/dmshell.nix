{ inputs, pkgs, lib, ...}:
let
  pfp = ../pfp/suletta_pfp.jpg;
in
{

  imports = [ inputs.dms.homeModules.dank-material-shell inputs.dms-plugin-registry.homeModules.default ];

  programs.dank-material-shell = {
    enable = true;
    dgop.package = inputs.dgop.packages.${pkgs.stdenv.hostPlatform.system}.default;
    enableSystemMonitoring = true;
    enableVPN = false;
    enableDynamicTheming = true;
    enableAudioWavelength = false;
    enableCalendarEvents = true;
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
      registryThemeVariants = {};
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
      enabledGpuPciIds = [];
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
      workspaceNameIcons = {};
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
      browserUsageHistory = {};
      appPickerViewMode = "grid";
      filePickerUsageHistory = {};
      sortAppsAlphabetically = false;
      appLauncherGridColumns = 4;
      spotlightCloseNiriOverview = true;
      spotlightSectionViewModes = {};
      appDrawerSectionViewModes = {};
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
      brightnessDevicePins = {};
      wifiNetworkPins = {};
      bluetoothDevicePins = {};
      audioInputDevicePins = {};
      audioOutputDevicePins = {};
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
      notificationRules = [];
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
      screenPreferences = {};
      showOnLastDisplay = {};
      niriOutputSettings = {};
      hyprlandOutputSettings = {};
      displayProfiles = {};
      activeDisplayProfile = {};
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
      systemMonitorVariants = [];
      desktopWidgetPositions = {};
      desktopWidgetGridSettings = {};
      desktopWidgetInstances = [];
      desktopWidgetGroups = [];
      builtInPluginSettings = {
        dms_settings_search = {
          trigger = "?";
        };
      };
      clipboardEnterToPaste = false;
      launcherPluginVisibility = {};
      launcherPluginOrder = [];
      configVersion = 5;
    };

    session = {
      isLightMode = false;
      doNotDisturb = false;
      wallpaperPath = ../wallpapers/bafkreidxnbp4exjkrvd7vpfylv4bfz5n4w66wpnuodip5kkq3mguqwyixi.jpg;
      perMonitorWallpaper = false;
      monitorWallpapers = {};
      perModeWallpaper = false;
      wallpaperPathLight = "";
      wallpaperPathDark = "";
      monitorWallpapersLight = {};
      monitorWallpapersDark = {};
      monitorWallpaperFillModes = {};
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
      monitorCyclingSettings = {};
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
      pinnedApps = [];
      barPinnedApps = [];
      dockLauncherPosition = 0;
      hiddenTrayIds = [];
      trayItemOrder = [];
      recentColors = [];
      showThirdPartyPlugins = false;
      launchPrefix = "";
      lastBrightnessDevice = "";
      brightnessExponentialDevices = {};
      brightnessUserSetValues = {};
      brightnessExponentValues = {};
      selectedGpuIndex = 0;
      nvidiaGpuTempEnabled = false;
      nonNvidiaGpuTempEnabled = false;
      enabledGpuPciIds = [];
      wifiDeviceOverride = "";
      weatherHourlyDetailed = true;
      hiddenApps = [];
      appOverrides = {};
      searchAppActions = true;
      vpnLastConnected = "";
      deviceMaxVolumes = {};
      hiddenOutputDeviceNames = [];
      hiddenInputDeviceNames = [];
      launcherLastMode = "all";
      appDrawerLastMode = "apps";
      niriOverviewLastMode = "apps";
      configVersion = 3;
    };
  };
}
