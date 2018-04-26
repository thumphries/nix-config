{ nixpkgs ? import <nixpkgs> {} }:
let
  private = nixpkgs.pkgs.callPackage ./private {};

  pkgs = nixpkgs.pkgs.callPackage ./pkgs {};

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

  xalt = nixpkgs.pkgs.callPackage ./xalt {
    themes = themes;
    config = {
      general = {
        terminal = ''${termite}/bin/termite'';
        border-width = 1;
      };
      xbar = {
        theme = theme;
        font-face = fonts.info.pragmatapro.pragmatapro.face;
        font-style = fonts.info.pragmatapro.pragmatapro.styles.regular;
        font-size = 14;
      };
    };
  };

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
      pkgs.acpilight
      pkgs.screenshot
      termite
      xalt
      xinitrc
      xsettingsd
      yabar
    ];
  }
