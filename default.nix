{ nixpkgs ? import <nixpkgs> {} }:
let
  private = nixpkgs.pkgs.callPackage ./private {};

  pkgs = nixpkgs.pkgs.callPackage ./pkgs {};

  fonts = nixpkgs.pkgs.callPackage ./fonts { private = private; };

  themes = nixpkgs.pkgs.callPackage ./terminal-themes {};

  theme = themes.fahrenheit;

  termite = nixpkgs.pkgs.callPackage ./termite {
    themes = themes;
    config = {
      theme = theme;
      font-face = fonts.info.pragmatapro.pragmatapro.face;
      font-style = fonts.info.pragmatapro.pragmatapro.styles.regular;
      font-size = 14;
    };
  };

  xalt = nixpkgs.pkgs.callPackage ./xalt {
    themes = themes;
    config = {
      general = {
        terminal = ''${termite}/bin/termite'';
        border-width = 1;
      };
      keymap = [
        { keybind = "M-x y"; command = { spawn = ''${termite}/bin/termite''; }; }
        { keybind = "M-<XF86MonBrightnessUp>"; command = { spawn = backlightUp; }; }
        { keybind = "M-<XF86MonBrightnessDown>"; command = { spawn = backlightDown; }; }
        { keybind = "M-<XF86AudioMute>"; command = { spawn = volumeMute; }; }
        { keybind = "M-<XF86AudioLowerVolume>"; command = { spawn = volumeDown; }; }
        { keybind = "M-<XF86AudioRaiseVolume>"; command = { spawn = volumeUp; }; }
      ];
      xbar = {
        theme = theme;
        font-face = fonts.info.pragmatapro.pragmatapro.face;
        font-style = fonts.info.pragmatapro.pragmatapro.styles.regular;
        font-size = 14;
      };
    };
  };

  backlightUp = ''${pkgs.acpilight}/bin/xbacklight -inc 10'';
  backlightDown = ''${pkgs.acpilight}/bin/xbacklight -dec 10'';
  volumeUp = ''${nixpkgs.pkgs.pamixer}/bin/pamixer -i 10'';
  volumeDown = ''${nixpkgs.pkgs.pamixer}/bin/pamixer -d 10'';
  volumeMute = ''${nixpkgs.pkgs.pamixer}/bin/pamixer --toggle-mute'';

  yabar = nixpkgs.pkgs.callPackage ./yabar {};

  compton = nixpkgs.pkgs.callPackage ./compton {
    config = {
      fade-delta = 10;
    };
  };

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
      fonts.env
      nixpkgs.pkgs.pamixer
      pkgs.acpilight
      pkgs.screenshot
      termite
      xalt
      xinitrc
      xsettingsd
      yabar
    ];
  }
