{ stdenv, callPackage, makeWrapper, symlinkJoin, writeTextFile, config ? {} }:
let
  wm = callPackage ./wm {};

  config-file = writeTextFile {
    name = "xalt-conf";
    executable = false;
    destination = "/etc/xalt.conf";
    text = ''
    '';
  };
in
  symlinkJoin {
    name = "xalt";

    paths = [ wm ];

    buildInputs = [ wm makeWrapper ];

    postBuild = ''
      wrapProgram $out/bin/xalt \
        --add-flags "-c ${config-file}/etc/xalt.conf"
    '';
  }
