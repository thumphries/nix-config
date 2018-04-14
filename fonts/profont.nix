{ lib, pkgs }:
let
  env = pkgs.profont;

  faces = {
    profont = {
      face = "ProFont";
      styles = {
        regular = "Regular";
      };
    };
  };
in
  { env = env; faces = faces; }
