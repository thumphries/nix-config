{ stdenv, callPackage, makeWrapper, symlinkJoin, writeTextFile, config ? {} }:
let
  wm = callPackage ./wm {};

  defaultConfig = {
    general = {
      terminal = "xterm";
    };
  };

  cfg = defaultConfig // config;

  config-file = writeTextFile {
    name = "xalt-conf";
    executable = false;
    destination = "/etc/xalt.conf";
    text = ''
      general:
        terminal: ${cfg.general.terminal}
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
