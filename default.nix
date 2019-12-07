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
      font-size = 14;
    };
  };

  emacs = nixpkgs.pkgs.callPackage ./emacs {};

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

  term = ''${termite}/bin/termite'';

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

  xinitrc = nixpkgs.pkgs.callPackage ./xinitrc {
    compton = compton;
    xalt = xalt;
    xsettingsd = xsettingsd;
  };
in
  nixpkgs.pkgs.buildEnv rec {
    name = "nix-config";

    meta.priority = 9;

    paths = [
      nixpkgs.pkgs.glibcLocales

      fztz
      glirc

      # aws
      nixpkgs.pkgs.awscli
      nixpkgs.pkgs.aws-vault

      emacs
      nixpkgs.pkgs.direnv
      nixpkgs.pkgs.fzf

      # haskell
      nixpkgs.pkgs.ghc

      # git et al
      nixpkgs.pkgs.cacert
      nixpkgs.pkgs.git
      nixpkgs.pkgs.tig

      # fancy coreutils replacements
      nixpkgs.pkgs.bat
      nixpkgs.pkgs.fd
      nixpkgs.pkgs.exa
      nixpkgs.pkgs.ripgrep
      nixpkgs.pkgs.sd

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
      nixpkgs.pkgs.nitrogen
      nixpkgs.pkgs.redshift
      nixpkgs.pkgs.xclip
      nixpkgs.pkgs.xidlehook
      pkgs.acpilight
      pkgs.screenshot
      xalt
      xinitrc
      xsettingsd

      # desktop
      fonts.env
      fzmenu
      rofi
      termite

      # web
      nixpkgs.pkgs.firefox

      # networking
      nixpkgs.pkgs.networkmanager_dmenu

      # db
      nixpkgs.pkgs.sqlite
    ];
  }
