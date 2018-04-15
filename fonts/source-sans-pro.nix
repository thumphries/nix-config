{ lib, pkgs }:
let
  env = pkgs.source-sans-pro;

  faces = {
    source-sans-pro = {
      face = "Source Sans Pro";
      styles = {
        regular = "Regular";
        semibold = "Semibold";
        bold = "Bold";
        italic = "Italic";
        semibold-italic = "Semibold Italic";
        bold-italic = "Bold Italic";
        light = "Light";
        black = "Black";
        black-italic = "Black Italic";
      };
    };
  };
in
  { env = env; faces = faces; }
