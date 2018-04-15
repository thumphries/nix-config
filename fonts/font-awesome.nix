{ lib, pkgs}:
let
  env = pkgs.font-awesome_5;

  faces = {
    font-awesome-5 = {
      face = "Font Awesome 5 Free";
      styles = {
        regular = "Regular";
        solid = "Solid";
        book = "Book";
      };
    };
    font-awesome-5-brands = {
      face = "Font Awesome 5 Brands";
      styles = {
        regular = "Regular";
      };
    };
  };
in
  { env = env; faces = faces; }
