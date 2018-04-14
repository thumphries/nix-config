{ lib, pkgs }:
let
  env = pkgs.terminus_font;

  faces = {
    terminus = {
      face = "Terminus";
      styles = {
        regular = "Regular";
        bold = "Bold";
      };
    };
  };
in
  { env = env; faces = faces; }
