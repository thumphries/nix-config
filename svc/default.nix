{ stdenv, symlinkJoin, writeShellScriptBin, daemontools, services }:
let
  script = writeShellScriptBin "svcinit" ''
    set -euo pipefail

    ROOT=${services}
    SVCD="$ROOT/svc"
    DEST=$(mktemp -d)
    MARKER="$HOME/.svc"

    if [ -d "$MARKER" ]; then
      echo "Service directory exists; is another svscan running?"
      echo "Fix with 'rm $MARKER'"
      exit 1
    fi

    if [ -d "$SVCD" ] && find "$ROOT/svc" -mindepth 1 | read; then
      for sf in $ROOT/svc/*; do
        s=$(basename $sf)
        mkdir "$DEST/$s"
        for f in run down; do
          FILE="$ROOT/svc/$s/$f"
          if [ -f "$FILE" ]; then
            ln -s "$FILE" "$DEST/$s/$f"
          fi
        done
      done
    else
      echo "No services found"
    fi

    cleanup () {
      if find "$DEST/" -mindepth 1 | read; then
        for sf in $DEST/*; do
          svc -kx "$sf"
        done
      fi
      kill $JOB
      rm "$MARKER"
      rm -rf "$DEST"
    }

    trap cleanup 1 2 3 6

    ln -s "$DEST" "$MARKER"
    svscan "$DEST" &
    JOB=$!
    wait "$JOB"
  '';
in
  symlinkJoin rec {
    name = "svc";
    paths = [ script ];
    buildInputs = [ ];
    meta = {
      description = "Service init script";
      license = stdenv.lib.licenses.bsd3;
    };
  }
