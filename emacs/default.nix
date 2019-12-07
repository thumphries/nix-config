{ stdenv, symlinkJoin, writeTextFile, emacs }:
let
in
  symlinkJoin {
      name = "emacstools";
      paths = [];
      buildInputs = [ emacs ];
    }
