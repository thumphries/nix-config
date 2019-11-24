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

  xaltt = pkgs: oldpkgs.pkgs.callPackage ./xalt {
    nixpkgs = pkgs;
    themes = themes;
    config = {
      general = {
        terminal = ''${term}'';
        border-width = 5;
        border-color = ''${theme.foreground}'';
        border-color-focused = ''${theme.color4}'';
        window-gaps = 15;
      };
      keymap = [
        { keybind = "<XF86MonBrightnessUp>"; command = { spawn = backlightUp10; }; }
        { keybind = "S-<XF86MonBrightnessUp>"; command = { spawn = backlightUp1; }; }
        { keybind = "C-S-<XF86MonBrightnessUp>"; command = { spawn = kbdBacklightUp; }; }
        { keybind = "<XF86MonBrightnessDown>"; command = { spawn = backlightDown10; }; }
        { keybind = "S-<XF86MonBrightnessDown>"; command = { spawn = backlightDown1; }; }
        { keybind = "C-S-<XF86MonBrightnessDown>"; command = { spawn = kbdBacklightDown; }; }
        { keybind = "<XF86AudioMute>"; command = { spawn = volumeMute; }; }
        { keybind = "<XF86AudioLowerVolume>"; command = { spawn = volumeDown; }; }
        { keybind = "<XF86AudioRaiseVolume>"; command = { spawn = volumeUp; }; }
        { keybind = "<XF86Display>"; command = { spawn = autorandr; }; }
        { keybind = "M-S-r"; command = { restart = {}; }; }
        { keybind = "M-<Return>"; command = { promote = {}; }; }
        { keybind = "M-a"; command = { pin = {}; }; }
        { keybind = "M-S-a"; command = { unpin = {}; }; }
        { keybind = "M-f"; command = { float = {}; }; }
        { keybind = "M-t"; command = { sink = {}; }; }
        { keybind = "M-m"; command = { magnify = {}; }; }
        { keybind = "M-g"; command = { fullscreen = {}; }; }
        { keybind = "M-S-4"; command = { spawn = screenshotSel; }; }
        { keybind = "M-o"; command = { spawn = promptCmd; }; }

        { keybind = "M-`"; command = { scratch = "term"; }; }
        { keybind = "M-u"; command = { scratch = "firefox"; }; }
        { keybind = "M-S-u"; command = { scratch = "firefox-work"; }; }
        { keybind = "M-i"; command = { scratch = "ncmpcpp"; }; }
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
      fztz
      glirc

      # aws
      nixpkgs.pkgs.awscli
      nixpkgs.pkgs.aws-vault

      nixpkgs.pkgs.emacs
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
      termite

      # web
      nixpkgs.pkgs.firefox

      # networking
      nixpkgs.pkgs.networkmanager_dmenu

      # db
      nixpkgs.pkgs.sqlite
    ];
  }
