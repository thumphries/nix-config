{ stdenv, lib, callPackage, makeWrapper, symlinkJoin, writeTextFile, config ? {} }:
let
  wm = callPackage ./wm {};

  defaultConfig = {
    general = {
      terminal = "xterm";
      border-width = 1;
    };
  };

  cfg = defaultConfig // config;

  config-file = writeTextFile {
    name = "xalt-conf";
    executable = false;
    destination = "/etc/xalt.conf";
    text = ''
      general:
        terminal: ${quote cfg.general.terminal}
        border-width: ${toString cfg.general.border-width}
    '';
  };

  quote = s : "\"" + lib.escape ["\""] s + "\"";
in
  symlinkJoin {
    name = "xalt";

    paths = [ wm config-file ];

    buildInputs = [ wm makeWrapper ];

    postBuild = ''
      wrapProgram $out/bin/xalt \
        --add-flags "-c ${config-file}/etc/xalt.conf"
    '';
  }
