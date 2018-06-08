{ stdenv, symlinkJoin, writeShellScriptBin
, compton, networkmanagerapplet, setxkbmap, xalt, xsetroot, xsettingsd }:
let
  script = writeShellScriptBin "xinitrc" ''
    set -euo pipefail
    ${xsetroot}/bin/xsetroot -cursor_name left_ptr
    ${setxkbmap}/bin/setxkbmap -option ctrl:nocaps
    ${xsettingsd}/bin/xsettingsd &
    ${compton}/bin/compton -b &
    ${networkmanagerapplet}/bin/nm-applet &
    ${xalt}/bin/xbar &
    ${xalt}/bin/xalt
  '';
in
  symlinkJoin rec {
    name = "xinitrc";

    paths = [ script ];

    buildInputs = [ ];

    meta = {
      description = "X init script";
      license = stdenv.lib.licenses.bsd3;
    };
  }
