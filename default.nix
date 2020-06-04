let
  pinned = pin:
    let
      path = ./. + pin;
      json = builtins.fromJSON (builtins.readFile path);
    in
      import ((import <nixpkgs> { }).fetchFromGitHub {
        owner = "NixOS";
        repo = "nixpkgs";
        inherit (json) rev sha256;
      }) { config = { }; };

  # Stuck in the past
  oldpkgs = pinned "/nixpkgs.old.json";
  glirc =
    (oldpkgs.pkgs.haskellPackages.extend (self: super: {vty = self.vty_5_25_1;})).glirc;
  pkgs = oldpkgs.pkgs.callPackage ./pkgs {};
  compton = oldpkgs.pkgs.callPackage ./compton {
    config = {
      fade-delta = 10;
    };
  };
  xalt = xaltt oldpkgs;

  nixpkgs = pinned "/nixpkgs.json";

  private = nixpkgs.pkgs.callPackage ./private {};

  fonts = nixpkgs.pkgs.callPackage ./fonts { private = private; };

  themes = nixpkgs.pkgs.callPackage ./terminal-themes {};

  theme = themes.ashe;

  termite = nixpkgs.pkgs.callPackage ./termite {
    themes = themes;
    config = {
      theme = theme;
      font-face = fonts.info.pragmatapro.pragmatapro.face;
      font-style = fonts.info.pragmatapro.pragmatapro.styles.regular;
      font-size = 16;
    };
  };

  term = ''${termite}/bin/termite'';
  runInTerminal = cmd : ''${term} -e "${cmd}"'';
  runInTerminalHold = cmd : ''${term} -e "${cmd}" --hold'';

  emacs = nixpkgs.pkgs.callPackage ./emacs {};
  emacsWorkspaceSession =
    nixpkgs.writeTextFile {
        name = "emacs-xalt";
        executable = true;
        destination = "/bin/emacs-xalt";
        text = ''
          #!/bin/sh -eu
          EMACS_SESSION="''${XALT_WORKSPACE}"
          export EMACS_SESSION
          ${emacs}/bin/emacs-session ensure
          ${emacs}/bin/emacs-session client -nw "$@"
        '';
      };

  emacsProjectFile =
    nixpkgs.writeTextFile {
        name = "emacs-xalt-project-open";
        executable = true;
        destination = "/bin/emacs-xalt-project-open";
        text = ''
          #!/bin/sh -eu
          git ls-files | fzf | xargs emacs-xalt
        '';
      };

  emacsNewFrame = runInTerminal ''${emacsWorkspaceSession}/bin/emacs-xalt'';
  emacsGitFile = runInTerminal ''${emacsProjectFile}/bin/emacs-xalt-project-open'';

  rofi =
    let
      minFlags = "-markup-rows -async-pre-read 25 -scroll-method 1";
      font = "${fonts.info.pragmatapro.pragmatapro.face} 18";
      # bg, fg, bgalt, hlbg, hlfg
      normal = "${theme.background},${theme.foreground},${theme.background},${theme.color0},${theme.color15}";
      # bg, border, separator
      window = "${theme.background},${theme.foreground},${theme.color0}";
      rofiTheme = "-font \"${font}\" -color-normal \"${normal}\" -color-window \"${window}\"";
    in nixpkgs.symlinkJoin {
        name = "rofi";
        paths = [nixpkgs.pkgs.rofi];
        buildInputs = [nixpkgs.makeWrapper nixpkgs.pkgs.glibcLocales];
        postBuild = ''
          wrapProgram $out/bin/rofi \
            --add-flags '${minFlags} ${rofiTheme}' \
            --set LOCALE_ARCHIVE "${nixpkgs.pkgs.glibcLocales}/lib/locale/locale-archive"

          makeWrapper $out/bin/rofi $out/bin/rofi-prompt \
            --add-flags '-dmenu -l 0 -p prompt'
          makeWrapper $out/bin/rofi $out/bin/rofi-select \
            --add-flags '-dmenu -i -format i -p select'
          makeWrapper $out/bin/rofi $out/bin/rofi-select-multi \
            --add-flags '-dmenu -i -format i -multi-select -p select'
          makeWrapper $out/bin/rofi $out/bin/rofi-run \
            --add-flags '-modi run -show run -show-icons -p run'
          makeWrapper $out/bin/rofi $out/bin/rofi-drun \
            --add-flags '-modi drun -show drun -show-icons -p launch'
          makeWrapper $out/bin/rofi $out/bin/rofi-window \
            --add-flags '-modi window,windowcd -show window -p window'
          makeWrapper $out/bin/rofi $out/bin/rofi-windowcd \
            --add-flags '-modi window,windowcd -show windowcd -p window'
        '';
      };
  rofiPrompt = ''${rofi}/bin/rofi-prompt'';
  rofiRun = ''${rofi}/bin/rofi-run'';
  rofiDrun = ''${rofi}/bin/rofi-drun'';
  rofiWindow = ''${rofi}/bin/rofi-window'';
  rofiWindowCd = ''${rofi}/bin/rofi-windowcd'';
  rofiSelect = ''${rofi}/bin/rofi-select'';
  rofiSelectMulti = ''${rofi}/bin/rofi-select-multi'';

  # automatic screen locking
  autolocker =
    nixpkgs.symlinkJoin {
      name = "autolocker";
      paths = [nixpkgs.pkgs.xidlehook];
      buildInputs = [nixpkgs.makeWrapper nixpkgs.pkgs.xidlehook];
      postBuild = ''
        OPTS='--not-when-fullscreen'
        TIMER1="--timer 300 'notify-send -t 9000 autolocker \"locking soon\"' true"
        TIMER2="--timer 30 '/usr/bin/env lockscreen || /usr/bin/env slock' true"
        makeWrapper $out/bin/xidlehook $out/bin/autolocker \
          --add-flags "$OPTS $TIMER1 $TIMER2"
      '';
    };

  # low battery -> notify-send
  batwatch =
    nixpkgs.writeTextFile {
        name = "batwatch";
        executable = true;
        destination = "/bin/batwatch";
        text = ''
          #!/bin/sh -eu
          while true; do
            battery_level=`acpi -b | grep -P -o '[0-9]+(?=%)'`
            if [ $battery_level -le 5 ]
            then
                notify-send -u critical -t 10000 "Low Battery" "Battery down to ''${battery_level}%!"
            fi
            sleep 60
          done
        '';
      };

  dunst =
    nixpkgs.symlinkJoin {
      name = "dunst";
      paths = [nixpkgs.pkgs.dunst dunstrc];
      buildInputs = [nixpkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/dunst --add-flags '-config ${dunstrc}/etc/dunstrc'
      '';
    };

  # notifications
  dunstrc =
    nixpkgs.writeTextFile {
        name = "dunstrc";
        executable = false;
        destination = "/etc/dunstrc";
        text = ''
          [frame]
              width = 0
              color = "#212121"

          [urgency_low]
              background = "#000000"
              foreground = "#ffffff"
              timeout = 10

          [urgency_normal]
              background = "#212121"
              foreground = "#ffffff"
              timeout = 10

          [urgency_critical]
              background = "#fbc02d"
              foreground = "#000000"
              timeout = 0

          [global]
              format = "<big><b>%s</b></big>\n%b\n%p\n"
              geometry = "300x5-50+75"
              font = Cantarell 12
              transparency = 10
              allow_markup = yes
              alignment = center
              separator_height = 2
              padding = 8
              horizontal_padding = 8
              separator_color = frame

          [shortcuts]
              close_all = ctrl+space
        '';
      };

  xaltt = pkgs: oldpkgs.pkgs.callPackage ./xalt {
    nixpkgs = pkgs;
    themes = themes;
    config = {
      general = {
        terminal = ''${term}'';
        selector = ''${rofiSelect}'';
        prompt = ''${rofiPrompt}'';
        border-width = 5;
        border-color = ''${theme.foreground}'';
        border-color-focused = ''${theme.color4}'';
        window-gaps = 15;
      };
      keymap = [
        # XF86 / hardware configuration
        (keybind "<XF86MonBrightnessUp>"       (spawn backlightUp10)    "Screen brightness +10")
        (keybind "S-<XF86MonBrightnessUp>"     (spawn backlightUp1)     "Screen brightness +1")
        (keybind "C-S-<XF86MonBrightnessUp>"   (spawn kbdBacklightUp)   "Keyboard brightness +50")
        (keybind "<XF86MonBrightnessDown>"     (spawn backlightDown10)  "Screen brightness -10")
        (keybind "S-<XF86MonBrightnessDown>"   (spawn backlightDown1)   "Screen brightness -1")
        (keybind "C-S-<XF86MonBrightnessDown>" (spawn kbdBacklightDown) "Keyboard brightness -50")
        (keybind "<XF86AudioMute>"             (spawn volumeMute)       "Mute")
        (keybind "<XF86AudioLowerVolume>"      (spawn volumeDown)       "Volume down")
        (keybind "<XF86AudioRaiseVolume>"      (spawn volumeUp)         "Volume up")
        (keybind "<XF86Display>"               (spawn autorandr)        "Detect displays")

        # WM process control
        (keybind "M-S-r"                       { restart = {}; }        "Restart WM")

        # Window management
        (keybind "M-<Return>"                  { promote = {}; }        "Promote")
        (keybind "M-a"                         { pin = {}; }            "Pin to all workspaces")
        (keybind "M-S-a"                       { unpin = {}; }          "Unpin from all workspaces")
        (keybind "M-f"                         { float = {}; }          "Float window")
        (keybind "M-t"                         { sink = {}; }           "Sink window")
        (keybind "M-m"                         { magnify = {}; }        "Magnify window")
        (keybind "M-g"                         { fullscreen = {}; }     "Fullscreen window")
        (keybind "M-S-4"                       (spawn screenshotSel)    "Take screenshot with selection")
        (keybind "M-S-h"                       { hide = {}; }           "Hide scratchpad")

        # Prompts and launchers
        (keybind "M-o"                         (spawn rofiDrun)         "Launch XDG application")
        (keybind "M-S-o"                       (spawn rofiRun)          "Launch shell command")
        (keybind "M-<Tab>"                     (spawn rofiWindowCd)     "Switch windows (current workspace)")
        (keybind "M-S-<Tab>"                   (spawn rofiWindow)       "Switch windows (all workspaces)")


        # Scratchpads
        (keybind "M-`"                         (scratch "term")         "")
        (keybind "M-u"                         (scratch "firefox")      "")
        (keybind "M-S-u"                       (scratch "firefox-work") "")
        (keybind "M-i"                         (scratch "ncmpcpp")      "")

        # Emacs
        (keybind "M-\\\\"                      (spawn emacsNewFrame)    "New emacs frame")
        (keybind "M-S-\\\\"                    (spawn emacsGitFile)     "Open a project file in a new emacs frame")
      ];
      rules = [
        { selector = { class = promptClass; }; action = { rect = promptRect; }; }
      ];
      scratchpads = [
        {
          name = "term";
          command = "${term} --role=scratchpad";
          selector = { role = "scratchpad"; };
          action = { rect = termRect; };
        }
        {
          name = "ncmpcpp";
          command = "${term} --role=ncmpcpp --exec=${nixpkgs.pkgs.ncmpcpp}/bin/ncmpcpp";
          selector = { role = "ncmpcpp"; };
          action = { rect = termRect; };
        }
        {
          name = "firefox";
          command = "firefox --class=foxpad";
          selector = { class = "foxpad";};
          action = { tile = {}; };
        }
        {
          name = "firefox-work";
          command = "firefox -p professional --class=foxpro";
          selector = { class = "foxpro"; };
          action = { tile = {}; };
        }
      ];
      xbar = {
        theme = theme;
        font-face = fonts.info.source-sans-pro.source-sans-pro.face;
        font-style = fonts.info.source-sans-pro.source-sans-pro.styles.regular;
        font-size = 14;
      };
    };
  };

  # Command / keybinding shorthand
  keybind = k : c : d :
    { keybind = k; command = c; description = d; };
  spawn = x : { spawn = x; };
  scratch = x : { scratch = x; };

  backlightUp1 = ''${pkgs.acpilight}/bin/xbacklight -inc 1'';
  backlightUp10 = ''${pkgs.acpilight}/bin/xbacklight -inc 10'';
  backlightDown1 = ''${pkgs.acpilight}/bin/xbacklight -dec 1'';
  backlightDown10 = ''${pkgs.acpilight}/bin/xbacklight -dec 10'';
  kbdBacklightUp = ''${pkgs.acpilight}/bin/xbacklight -ctrl tpacpi::kbd_backlight -inc 50'';
  kbdBacklightDown = ''${pkgs.acpilight}/bin/xbacklight -ctrl tpacpi::kbd_backlight -dec 50'';
  volumeUp = ''${nixpkgs.pkgs.pamixer}/bin/pamixer -i 10'';
  volumeDown = ''${nixpkgs.pkgs.pamixer}/bin/pamixer -d 10'';
  volumeMute = ''${nixpkgs.pkgs.pamixer}/bin/pamixer --toggle-mute'';
  autorandr = ''${nixpkgs.pkgs.autorandr}/bin/autorandr --change --default default --skip-options=gamma'';
  screenshotSel = ''${pkgs.screenshot}/bin/screenshot'';

  termRect = {
    x = 0.1;
    y = 0.1;
    w = 0.8;
    h = 0.33;
  };

  promptCmd = ''${term} --class=${promptClass} -e "sh -c ${fzmenu}/bin/fzmenu_run"'';
  promptClass = "fzmenu";
  promptRect = {
    x = 0.0;
    y = 0.0;
    w = 1.0;
    h = 0.2;
  };

  fzmenu = nixpkgs.pkgs.callPackage ./fzmenu {};
  fztz = nixpkgs.pkgs.callPackage ./fztz {};

  xsettingsd = nixpkgs.pkgs.callPackage ./xsettingsd {};

  arbtt =
    nixpkgs.symlinkJoin {
      name = "arbtt-configured";
      paths = [nixpkgs.pkgs.haskellPackages.arbtt arbttCfg];
      buildInputs = [nixpkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/arbtt-stats \
          --add-flags "--categorizefile=${arbttCfg}/etc/arbtt/categorize.cfg"
        makeWrapper $out/bin/arbtt-stats $out/bin/arbtt-program-stats \
          --add-flags "-c Program"
        makeWrapper $out/bin/arbtt-stats $out/bin/arbtt-desktop-stats \
          --add-flags "-c Desktop"
        makeWrapper $out/bin/arbtt-stats $out/bin/arbtt-time-stats \
          --add-flags "-c Time"
      '';
    };

  arbttCfg =
    nixpkgs.writeTextFile {
        name = "categorize.cfg";
        executable = false;
        destination = "/etc/arbtt/categorize.cfg";
        text = ''
        -- -*- mode: haskell; -*-

        -- A rule that probably everybody wants. Being inactive for over a minute
        -- causes this sample to be ignored by default.
        $idle > 60 ==> tag inactive,


        -- Simple rule that just tags the current program
        tag Program:$current.program,

        -- Another simple rule, just tags the current desktop (a.k.a. workspace)
        tag Desktop:$desktop,

        current window $title =~ /^(.*) - Mozilla Firefox$/ ==> tag Web,
        current window $title =~ /^(.*)Twitter - Mozilla Firefox$/ ==> tag Web:Twitter,
        current window $title =~ /^(.*)Fastmail - Mozilla Firefox$/ ==> tag Web:Mail,
        current window $title =~ /^(.*)Todoist - Mozilla Firefox$/ ==> tag Web:Todoist,


        -- githubs
        -- OrgName/project: description - Mozilla Firefox
        -- projectname/filepath at master · OrgName/project - Mozilla Firefox
        -- PR title by prauthor · Pull Request #223 · OrgName/project - Mozilla Firefox

        -- slacks
        -- current window $title =~ /^Slack (.*) - Mozilla Firefox$/ ==> tag Web:Slack,

        -- zooms

        current window $program =~ /termite/ ==> tag Term,


        -- $time evaluates to local time.

        $time >=  8:00 && $time < 10:00 ==> tag Time:Early,
        $time >= 10:00 && $time < 14:00 ==> tag Time:Morning,
        $time >= 14:00 && $time < 18:30 ==> tag Time:Afternoon,
        $time >= 18:30 && $time < 23:00 ==> tag Time:Evening,
        $time >= 23:00 || $time <  6:00 ==> tag Time:Night,

        -- This tag always refers to the last 24h
        -- $sampleage <= 24:00 ==> tag last-day,
        '';
      };


  xinitrc = nixpkgs.pkgs.callPackage ./xinitrc {
    arbtt = arbtt;
    autolocker = autolocker;
    batwatch = batwatch;
    compton = compton;
    dunst = dunst;
    xalt = xalt;
    xsettingsd = xsettingsd;
  };

  gocmds = nixpkgs.pkgs.callPackage ./gocmds {
    goinstalls = [
      {
        name = "ghq";
        package = "github.com/motemen/ghq";
        revision = "7ba9b5f82952dc930f289262a2df7bafb6bd53bf";
        sha = "2b4a72eb1f387f9a6246d830105d8156bf1fbc26";
        binaries = ["ghq"];
      }
      {
        name = "wtf";
        package = "github.com/wtfutil/wtf";
        revision = "5291a31afd9a525342ab62896423a00e06f3811f";
        sha = "49de074784f3b08a764bbe453db893e7d7dfe78a";
        binaries = ["wtf"];
      }
      {
        name = "hound";
        package = "github.com/thumphries/hound";
        revision = "8d548222b98419ef05f1e0f11a5f9d06cc0f15be";
        sha = "ffa638b4f36509c6df21b105c187af48640c5f15";
        binaries = ["hound" "houndd"];
      }
      {
        name = "todoist";
        package = "github.com/sachaos/todoist";
        revision = "ef5aa3d1bfee7823f266b2d205acf87d28e3b7b1";
        sha = "ad0bd617d4fdfd96708f8d4855850c3fb4b4a2a9";
        binaries = ["todoist"];
      }
      {
        name = "gh";
        package = "github.com/cli/cli";
        revision = "96dc4376a17fe26c8fe6a82891f610d35095d836"; # v0.5.5
        sha = "20d4a324b8aec11c4ec3a411556d9ff461d562da";
        binaries = ["gh"];
      }
    ];
  };
in
  nixpkgs.pkgs.buildEnv rec {
    name = "nix-config";

    meta.priority = 9;

    paths = [
      nixpkgs.pkgs.glibcLocales

      # base utils
      nixpkgs.pkgs.htop
      nixpkgs.pkgs.tmux

      # git et al
      nixpkgs.pkgs.cacert
      nixpkgs.pkgs.git
      nixpkgs.pkgs.git-lfs
      nixpkgs.pkgs.tig

      # fancy coreutils replacements
      nixpkgs.pkgs.bat
      nixpkgs.pkgs.fd
      nixpkgs.pkgs.exa
      nixpkgs.pkgs.ripgrep
      nixpkgs.pkgs.sd

      fztz
      glirc

      # aws
      nixpkgs.pkgs.awscli
      nixpkgs.pkgs.aws-vault

      emacs
      emacsWorkspaceSession
      emacsGitFile
      emacsProjectFile

      nixpkgs.pkgs.direnv
      nixpkgs.pkgs.fzf

      nixpkgs.pkgs.htop
      nixpkgs.pkgs.tree

      # haskell
      nixpkgs.pkgs.ghc
      nixpkgs.pkgs.ghcid

      # go tools
      gocmds

      # scripting
      nixpkgs.pkgs.shellcheck

      # benchmarking
      nixpkgs.pkgs.haskellPackages.bench
      nixpkgs.pkgs.hyperfine
      nixpkgs.pkgs.wrk2

      # json manipulation
      nixpkgs.pkgs.jq
      nixpkgs.pkgs.jid
      #nixpkgs.pkgs.jiq

      # sound
      nixpkgs.pkgs.pamixer
      nixpkgs.pkgs.playerctl

      # mpd
      nixpkgs.pkgs.mpd
      nixpkgs.pkgs.mpdscribble
      nixpkgs.pkgs.mpdris2
      nixpkgs.pkgs.ncmpcpp

      # x11
      nixpkgs.pkgs.autorandr
      nixpkgs.pkgs.libnotify
      nixpkgs.pkgs.nitrogen
      nixpkgs.pkgs.redshift
      nixpkgs.pkgs.xclip
      #nixpkgs.pkgs.xidlehook
      pkgs.screenshot
      arbtt
      autolocker
      dunst
      xalt
      xinitrc
      xsettingsd

      # desktop
      fonts.env
      fzmenu
      rofi
      termite

      # laptop problems
      nixpkgs.pkgs.acpi
      batwatch
      pkgs.acpilight

      # web
      nixpkgs.pkgs.firefox

      # networking
      nixpkgs.pkgs.networkmanager_dmenu

      # db
      nixpkgs.pkgs.sqlite

      # image manipulation
      nixpkgs.pkgs.imagemagick
      nixpkgs.pkgs.potrace
      nixpkgs.pkgs.librsvg

      # work?
      #nixpkgs.pkgs.zoom-us
    ];
  }
