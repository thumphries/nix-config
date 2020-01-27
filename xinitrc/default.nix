{ stdenv, symlinkJoin, writeShellScriptBin
, arbtt, autolocker, autorandr, compton, dunst, redshift, setxkbmap
, xalt, xset, xsetroot, xsettingsd }:
let
  script = writeShellScriptBin "session" ''
    set -euo pipefail
    ${xsetroot}/bin/xsetroot -cursor_name left_ptr
    ${setxkbmap}/bin/setxkbmap -option ctrl:nocaps
    ${xset}/bin/xset r rate 180 25
    ${autorandr}/bin/autorandr --change --skip-options=gamma --default clone-largest &>/dev/null
    while true; do
      sleep 5
      ${autorandr}/bin/autorandr --change --skip-options=gamma --default clone-largest &>/dev/null
    done &
    ${redshift}/bin/redshift &
    ${xsettingsd}/bin/xsettingsd &
    ${compton}/bin/compton -b &
    ${arbtt}/bin/arbtt-capture &
    ${dunst}/bin/dunst &>/dev/null &
    ${autolocker}/bin/autolocker &
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
