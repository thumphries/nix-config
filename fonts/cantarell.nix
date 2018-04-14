{ lib, pkgs }:
let
  env = pkgs.cantarell-fonts;

  faces = {
    cantarell = {
      face = "Cantarell";
      styles = {
        regular = "Regular";
        thin = "Thin";
        light = "Light";
        bold = "Bold";
        extra-bold = "Extra Bold";
      };
    };
  };
in
  { env = env; faces = faces; }
