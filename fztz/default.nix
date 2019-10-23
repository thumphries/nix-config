{ stdenv, makeWrapper, symlinkJoin, writeTextFile, fzf }:
let
  fztz = writeTextFile {
    name = "fztz";
    executable = true;
    destination = "/bin/fztz";
    text = ''
      #!/bin/sh -eu
      ZONEINFO=/usr/share/zoneinfo
      LOCALTIME=/etc/localtime
      find "$ZONEINFO" -type f \
        -exec realpath --relative-to "$ZONEINFO" {} \; | \
        egrep -e "^[A-Z]" | \
        ${fzf}/bin/fzf --preview="echo -n \"{}: \"; TZ={} date" --preview-window=top:1 --inline-info --prompt="TZ> " | \
        (read NEWTZ; sudo ln -sf "''${ZONEINFO}/''${NEWTZ}" "$LOCALTIME")
      date
    '';
  };
in
  symlinkJoin {
    name = "fzmenu";

    paths = [ fztz ];

    buildInputs = [ fzf ];
  }
