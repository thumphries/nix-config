{ nixpkgs ? import <nixpkgs> {} }:
let
  fonts = nixpkgs.pkgs.callPackage ./fonts { };

  themes = nixpkgs.pkgs.callPackage ./terminal-themes {};

  termite = nixpkgs.pkgs.callPackage ./termite {
    config = {
      theme = themes.fahrenheit;
      font-face = fonts.info.source-code-pro.source-code-pro.face;
      font-style = fonts.info.source-code-pro.source-code-pro.styles.regular;
      font-size = 12;
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
