{ stdenv, symlinkJoin, writeShellScriptBin
, autorandr, compton, redshift, setxkbmap, xalt, xsetroot, xsettingsd }:
let
  script = writeShellScriptBin "session" ''
    set -euo pipefail
    ${xsetroot}/bin/xsetroot -cursor_name left_ptr
    ${setxkbmap}/bin/setxkbmap -option ctrl:nocaps
    ${autorandr}/bin/autorandr --change --default default
    while true; do
      sleep 5
      ${autorandr}/bin/autorandr --change --default default
    done &
    ${redshift}/bin/redshift &
    ${xsettingsd}/bin/xsettingsd &
    ${compton}/bin/compton -b &
    ${xalt}/bin/xbar &
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
