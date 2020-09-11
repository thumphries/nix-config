{ lib, pkgs, private }:
let
  fonts = {
    cantarell = pkgs.callPackage ./cantarell.nix {};
    font-awesome = pkgs.callPackage ./font-awesome.nix {};
    pragmatapro = pkgs.callPackage ./pragmatapro.nix { private = private; };
    source-code-pro = pkgs.callPackage ./source-code-pro.nix {};
    source-sans-pro = pkgs.callPackage ./source-sans-pro.nix {};
    terminus = pkgs.callPackage ./terminus.nix {};
  };

  env =
    pkgs.buildEnv rec {
      name = "fonts";

      meta.priority = 9;

      paths = builtins.map (f: f.env) (builtins.attrValues fonts);
    };

  info = lib.mapAttrs (fn: fv: fv.faces) fonts;
in {
    env = env;
    info = info;
  }
