{ lib, pkgs }:
let
  env = pkgs.source-code-pro;

  faces = {
    source-code-pro = {
      face = "Source Code Pro";
      styles = {
        regular = "Regular";
      };
    };
  };
in
  { env = env; faces = faces; }
