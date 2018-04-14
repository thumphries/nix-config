{ pkgs ? (import <nixpkgs> {}).pkgs }:
let
  themes = pkgs.callPackage ./terminal-themes {};

  termite = pkgs.callPackage ./termite {
    config = {
      theme = themes.fahrenheit;
    };
  };
in
  pkgs.buildEnv rec {
    name = "nix-config";

    meta.priority = 9;

    paths = [
      termite
    ];
  }
