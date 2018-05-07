{ stdenv, makeWrapper, symlinkJoin, writeTextFile, fzf }:
let
  fzmenu = writeTextFile {
    name = "fzmenu";
    executable = true;
    destination = "/bin/fzmenu";
    text = ''
      #!/bin/sh
      ${fzf}/bin/fzf --reverse "$@"
    '';
  };

  fzmenu-path = writeTextFile {
    name = "fzmenu-path";
    executable = true;
    destination = "/bin/fzmenu_path";
    text = ''
      #!/bin/sh
      compgen -c | sort | uniq
    '';
  };

  fzmenu-run = writeTextFile {
    name = "fzmenu-run";
    executable = true;
    destination = "/bin/fzmenu_run";
    text = ''
      #!/bin/sh
      ${fzmenu-path}/bin/fzmenu_path \
        | ${fzmenu}/bin/fzmenu --preview="man {}" \
        | (/bin/sh &)
    '';
  };
in
  symlinkJoin {
    name = "fzmenu";

    paths = [ fzmenu fzmenu-path fzmenu-run ];

    buildInputs = [ fzf ];
  }
