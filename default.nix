{ nixpkgs ? import <nixpkgs> {} }:
let
  private = nixpkgs.pkgs.callPackage ./private {};

  fonts = nixpkgs.pkgs.callPackage ./fonts { private = private; };

  themes = nixpkgs.pkgs.callPackage ./terminal-themes {};

  termite = nixpkgs.pkgs.callPackage ./termite {
    config = {
      theme = themes.fahrenheit;
      font-face = fonts.info.pragmatapro.pragmatapro.face;
      font-style = fonts.info.pragmatapro.pragmatapro.styles.regular;
      font-size = 14;
    };
  };
in
  nixpkgs.pkgs.buildEnv rec {
    name = "nix-config";

    meta.priority = 9;

    paths = [
      termite
      fonts.env
    ];
  }
