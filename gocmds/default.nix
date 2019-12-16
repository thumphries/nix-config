{ stdenv, symlinkJoin, writeTextFile, go, musl, goinstalls }:
let
  goLazyBuild = writeTextFile {
      name = "go-lazy-build";
      executable = true;
      destination = "/bin/go-lazy-build";
      text = ''
        #!/bin/sh -eux
        PKG=$1
        REV=$2
        SHA=$3
        OUT=$4

        >&2 echo "Building $PKG..."

        TMPBINDIR=$(mktemp -d)
        cd $TMPBINDIR
        git clone "https://$PKG" src
        cd src
        git checkout "$REV"
        git submodule init
        git submodule sync
        git submodule update
        rm -rf .git

        hash_it () {
          find . ! -path . -type f \( -exec sha1sum {} \; \) 2>&1 \
            | awk '{print $1}' | sort \
            | sha1sum | awk '{print $1}'
        }

        check_it () {
          GOT=$(hash_it)
          if [ ! "$GOT" = "$SHA" ]; then
            >&2 echo "EXPECT: $SHA"
            >&2 echo "ACTUAL: $GOT"
            >&2 echo "Source tree did not hash properly"
            exit 1
          fi
        }

        check_it

        if [ ! -f go.mod ]; then
          ${go}/bin/go mod init "$PKG"
        fi

        ${go}/bin/go mod download
        ${go}/bin/go mod verify

        export GOBIN="''${TMPBINDIR}/bin"
        mkdir -p $GOBIN
        unset GOPATH
        export CC=${musl.dev}/bin/musl-gcc
        ${go}/bin/go install --ldflags "-linkmode external -extldflags \"-static\"" ./...

        mkdir -p "$OUT"
        find "$GOBIN" -type f -executable -exec cp {} $OUT/ \;
        find "$OUT" -type f -executable

        rm -rf "''${TMPBINDIR}"
      '';
    };

  goLazy = writeTextFile {
      name = "go-lazy";
      executable = true;
      destination = "/bin/go-lazy";
      text = ''
        #!/bin/sh -eu

        PKG="$1"
        REV="$2"
        SHA="$3"

        OUTDIR="$HOME/.cmd/$PKG/$REV"

        if [ ! -d "$OUTDIR" ]; then
          ${goLazyBuild}/bin/go-lazy-build "$PKG" "$REV" "$SHA" "$OUTDIR"
        fi
        echo ''${OUTDIR}
      '';
    };

    builder = pkg :
      ''${goLazy}/bin/go-lazy "${pkg.package}" "${pkg.revision}" "${pkg.sha}"'';
    buildAll =
      builtins.map (pkg: builder pkg) goinstalls;

    goStrict = writeTextFile {
      name = "go-strict";
      executable = true;
      destination = "/bin/go-strict";
      text = ''
        #!/bin/sh -eu
        ${builtins.concatStringsSep "\n" buildAll}
      '';
    };

    goBins =
      builtins.map
        (pkg :
          builtins.map
            (bin :
              writeTextFile {
                name = pkg.name + "-" + bin;
                executable = true;
                destination = "/bin/" + bin;
                text = ''
                  #!/bin/sh -eu
                  OUT=$(${builder pkg})
                  exec "$OUT/${bin}" "$@"
                '';
              }) pkg.binaries) goinstalls;
in
  symlinkJoin {
      name = "gocmds";
      paths = [ (builtins.concatLists goBins) goStrict ];
      buildInputs = [ go musl.dev goLazy goLazyBuild ];
    }
