{ lib, private }:
let
  env = private.pragmatapro;

  faces = {
    pragmatapro = {
      face = "Essential PragmataPro";
      styles = {
        regular = "Regular";
      };
    };
  };
in
  { env = env; faces = faces; }
