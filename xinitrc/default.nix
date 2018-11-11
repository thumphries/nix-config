{ stdenv, symlinkJoin, writeShellScriptBin
, compton, moreutils, svcinit, setxkbmap, xalt, xsetroot, xsettingsd }:
let
  script = writeShellScriptBin "session" ''
    set -euo pipefail
    ${xsetroot}/bin/xsetroot -cursor_name left_ptr
    ${setxkbmap}/bin/setxkbmap -option ctrl:nocaps
    ${svcinit}/bin/svcinit | ${moreutils}/bin/ts "[%FT%TZ]"  &
    ${xalt}/bin/xalt
  '';

  init = writeShellScriptBin "xinitrc" ''
    set -euo pipefail
    dbus-launch ${script}/bin/session
  '';
in
  symlinkJoin rec {
    name = "xinitrc";

    paths = [ init ];

    buildInputs = [ ];

    meta = {
      description = "X init script";
      license = stdenv.lib.licenses.bsd3;
    };
  }
