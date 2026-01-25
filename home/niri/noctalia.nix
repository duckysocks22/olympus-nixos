{ pkgs, inputs, ...}:
{
  imports = [ inputs.noctalia.homeModules.default ];

  home.packages = [
    pkgs.gtk3
    pkgs.kdePackages.breeze-icons
    pkgs.qt6Packages.qt6ct
    ];

  home.sessionVariables = {
    QS_ICON_THEME="breeze-dark";
  };

  programs.noctalia-shell = {
    enable = true;
    settings = {
      settingsVersion = 0;
      bar = {
        position = "top";
        monitors = [ ];
	density = "default";
	showOutline = false;
	showCapsule = true;
	capsuleOpacity = 0.8;
	backgroundOpacity = 0.94;
	useSeparateOpacity = false;
	floating = false;
	marginVertical = 4;
	marginHorizontal = 4;
	outerCorners = true;
	exclusive = true;
	hideOnOverview = false;
	widgets = {
          left = [
            {
	      id = "Launcher";
	    }
	    {
	      id = "Clock";
	    }
	    {
	      id = "SystemMonitor";
	    }
	    {
	      id = "ActiveWindow";
	    }
	  ];
	  center = [
            {
	      id = "Workspace";
	    }
	  ];
	  right = [
            {
              id = "Tray";
	    }
	    {
	      id = "NotificationHistory";
	    }
	    {
	      id = "Battery";
	    }
	    {
	      id = "Volume";
	    }
	    {
	      id = "Brightness";
	    }
	    {
	      id = "ControlCenter";
	    }
	  ];
	};
	screenOverrides = [ ];
      };
      general = {
        avatarImage = "";
        dimmerOpacity = 0.2;
	showScreenCorners = true;
	forceBlackScreenCorners = false;
	scaleRatio = 1;
	radiusRatio = 1;
	iRadiusRatio = 1;
	boxRadiusRatio = 1;
	animationSpeed = 1.2;
	animationDisabled = false;
	compactLockScreen = false;
	lockOnSuspend = true;
	showSessionButtonsOnmLockScreen = true;
	enableShadows = true;
	shadowDirection = "bottom_right";
	shadowOffsetX = 2;
	shadowOffsetY = 3;
	language = "";
	allowPanelsOnScreenWithoutBar = true;
	showChangelogOnStartup = true;
	telemetryEnabled = false;
	enableLockScreenCountdown = true;
	lockScreenCountdownDuration = 10000;
      };
      ui = {
        fontDefault = "DejaVu Sans Light";
	fontFixed = "";
	fontDefaultScale = 1;
	fontFixedScale = 1;
	tooltipsEnabled = true;
	panelBackgroundOpacity = 0.93;
	panelsAttachedToBar = true;
	settingsPanelMode = "attached";
	wifiDetailsViewMode = "grid";
	bluetoothDetailsViewMode = "grid";
	networkPanelView = "eth";
	bluetoothHideUnnamedDevices = true;
	boxBorderEnabled = false;
      };
      location = {
        name = "New Castle";
	weatherEnabled = true;
	weatherShowEffects = true;
	useFahrenheit = true;
	use12hourFormat = true;
	showWeekNumberInCalendar = false;
	showCalenderEvents = true;
	showCalenderWeather = true;
	analogClockInCalendar = false;
	firstDatOfWeek = -1;
	hideWeatherTimezone = false;
	hideWeatherCityName = false;
      };
      calender = {
        cards = [
          {
	    enabled = true;
	    id = "calendar-header-card";
	  }
	  {
	    enabled = true;
	    id = "calendar-month-card";
	  }
	  {
	    enabled = true;
	    id = "weather-card";
	  }
	];
      };
      wallpaper = {
        enabled = true;
	overviewEnabled = false;
	directory = "";
	monitorDirectories = [ ];
	enableMultiMonitorDirectories = false;
	showHiddenFiles = false;
	viewMode = "single";
	setWallpaperOnAllMonitors = true;
	fillMod = "crop";
	fillColor = "#000000";
	useSolidColor = false;
	solidColor = "#1a1a2e";
	automationEnabled = false;
	wallpaperChangeMode = "static";
	randomIntervalSec = 300;
	transitionDuration = 1500;
	transitionType = "random";
	transitionEdgeSmoothness = 0.05;
	panelPosition = "follow_bar";
	hideWallpaperFilenames = false;
	useWallhaven = false;
	wallhavenQuery = "";
	wallhavenSorting = "relevance";
	wallhavenOrder = "desc";
	wallhavenCategories = "111";
	wallhavenPurity = "100";
	wallhavenRations = "";
	wallhavenApiKey = "";
	wallhavenResolutionMode = "atleast";
	wallhavenResolutionWidth = "";
	wallhavenResoltuionHeight = "";
      };
      appLauncher = {
        enableClipboardHistory = true;
	autoPasteClipboard = false;
	enableClipPreview = true;
	clipboardWrapText = true;
	position = "center";
	pinnedApps = [ ];
	useApp2Unit = false;
	sortByMostUsed = true;
	terminalCommand = "kitty -e";
	customLaunchPrefixEnabled = false;
	customLaunchPrefix = "";
	viewMode = "list";
	showCategories = true;
	iconMode = "tabler";
	showIconBackground = false;
	enableSettingsSearch = true;
	ignoreMouseInput = false;
	screenshotAnnotationTool = "";
      };
      controlCenter = {
        position = "close_to_bar_button";
	diskPath = "/";
	shortcuts = {
          left = [
            {
	      id = "Network";
	    }
	    {
	      id = "Bluetooth";
	    }
	    {
	      id = "WallpaperSelector";
	    }
	    {
	      id = "NoctaliaPerformance";
	    }
	  ];
	  right = [
            {
	      id = "Notifications";
	    }
	    {
	      id = "PowerProfile";
	    }
	    {
	      id = "KeepAwake";
	    }
	    {
	      id = "NightLight";
	    }
	  ];
	};
	cards = [
          {
	    enabled = true;
	    id = "profile-card";
	  }
	  {
	    enabled = true;
	    id = "shortcuts-card";
	  }
	  {
	    enabled = true;
	    id = "audio-card";
	  }
	  {
	    enabled = true;
	    id = "brightness-card";
	  }
	  {
	    enabled = true;
	    id = "weather-card";
	  }
	  {
	    enabled = true;
	    id = "media-sysmon-card";
	  }
	];
      };
      systemMonitor = {
        cpuWarningThreshold = 80;
	cpuCriticalThreshold = 90;
	tempWarningThreshold = 80;
        tempCriticalThreshold = 90;
        gpuWarningThreshold = 80;
        gpuCriticalThreshold = 90;
        memWarningThreshold = 80;
        memCriticalThreshold = 90;
        swapWarningThreshold = 80;
        swapCriticalThreshold = 90;
        diskWarningThreshold = 80;
        diskCriticalThreshold = 90;
        cpuPollingInterval = 3000;
        tempPollingInterval = 3000;
        gpuPollingInterval = 3000;
        enableDgpuMonitoring = false;
        memPollingInterval = 3000;
        diskPollingInterval = 30000;
        networkPollingInterval = 3000;
        loadAvgPollingInterval = 3000;
        useCustomColors = false;
        warningColor = "";
        criticalColor = "";
        externalMonitor = "resources || missioncenter || jdsystemmonitor || corestats || system-monitoring-center || gnome-system-monitor || plasma-systemmonitor || mate-system-monitor || ukui-system-monitor || deepin-system-monitor || pantheon-system-monitor";
      };
      dock = {
        enabled = false;
	position = "bottom";
	displayMode = "auto_hide";
	backgroundOpacity = 1;
	floatingRatio = 1;
	size = 1;
	onlySameOutput = true;
	monitors = [ ];
	pinnedApps = [ ];
	colorizeIcons = false;
	pinnedStatic = false;
	inactiveIndicators = false;
	deadOpacity = 0.6;
	animationSpeed = 1;
      };
      network = {
        wifiEnabled = true;
	bluetoothRssiPollingEnabled = false;
	bluetoothRssiPollIntervalMs = 10000;
	wifiDetailsViewMode = "grid";
	bluetoothDetailsViewMode = "grid";
	bluetoothHideUnnamedDevices = false;
      };
      sessionMenu = {
        enableCountdown = true;
	countdownDuraction = 5000;
	position = "center";
	showHeader = true;
	largeButtonStyle = false;
	largeButtonsLayout = "grid";
	showNumberLabels = true;
	powerOptions = [
          {
            action = "lock";
            enabled = true;
          }
          {
            action = "suspend";
            enabled = true;
          }
          {
            action = "hibernate";
            enabled = true;
          }
          {
            action = "reboot";
            enabled = true;
          }
          {
            action = "logout";
            enabled = true;
          }
          {
            action = "shutdown";
            enabled = true;
          }
        ];
      };
      notifications = {
        enabled = true;
        monitors = [ ];
        location = "top_right";
        overlayLayer = true;
        backgroundOpacity = 1;
        respectExpireTimeout = false;
        lowUrgencyDuration = 3;
        normalUrgencyDuration = 8;
        criticalUrgencyDuration = 15;
        enableKeyboardLayoutToast = true;
        saveToHistory = {
          low = true;
          normal = true;
          critical = true;
	};
	sounds = {
          enabled = false;
          volume = 0.5;
          separateSounds = false;
          criticalSoundFile = "";
          normalSoundFile = "";
          lowSoundFile = "";
          excludedApps = "discord,firefox,chrome,chromium,edge";
        };
	enableMediaToast = false;
      };
      osd = {
        enabled = true;
        location = "top_right";
        autoHideMs = 2000;
        overlayLayer = true;
        backgroundOpacity = 1;
        enabledTypes = [
          0
          1
          2
        ];
        monitors = [ ];
      };
      audio = {
        volumeStep = 5;
        volumeOverdrive = false;
        cavaFrameRate = 30;
        visualizerType = "linear";
        mprisBlacklist = [ ];
        preferredPlayer = "";
        volumeFeedback = false;
      };
      brightness = {
        brightnessStep = 5;
        enforceMinimum = true;
        enableDdcSupport = false;
      };
      colorSchemes = {
        useWallpaperColors = false;
        predefinedScheme = "Noctalia (default)";
        darkMode = true;
        schedulingMode = "off";
        manualSunrise = "06:30";
        manualSunset = "18:30";
        generationMethod = "tonal-spot";
        monitorForColors = "";
      };
      templates = {
        activeTemplates = [ ];
        enableUserTheming = false;
      };
      nightLight = {
        enabled = true;
        forced = false;
        autoSchedule = true;
        nightTemp = "4000";
        dayTemp = "6500";
        manualSunrise = "08:30";
        manualSunset = "22:00";
      };
      hooks = {
        enabled = false;
        wallpaperChange = "";
        darkModeChange = "";
        screenLock = "";
        screenUnlock = "";
        performanceModeEnabled = "";
        performanceModeDisabled = "";
        startup = "";
        session = "";
      };
      desktopWidgets = {
        enabled = false;
        gridSnap = false;
        monitorWidgets = [ ];
      };
    };
  };
}
