{ stdenv, lib, makeWrapper, symlinkJoin, writeTextFile, yabar-unstable, config ? {} }:
let
  defaultConfig = {
    font-face = "Cantarell";
    font-size = 14;
  };

  cfg = defaultConfig // config;

  config-file = writeTextFile {
    name = "yabar-conf";
    executable = false;
    destination = "/etc/yabar.conf";
    text = ''
      bar-list = ["topbar"];
      topbar:{
        font: "${cfg.font-face}, FontAwesome Bold ${toString cfg.font-size}";
        block-list: ["workspaces", "date"];
        position: "top";
        height: 40;
        //If you want transparency, use argb, not rgb
        background-color-rgb: 0x000000;
        underline-size: 2;
        overline-size: 2;
        slack-size: 4;
        #border-size: 2;
        #monitor: "LVDS1 HDMI1"; # get names from `xrandr`

        workspaces: {
          exec: "socat unix-connect:/tmp/xmonad.sock stdio";
          type: "persist";
          align: "left";
          justify: "left";
          fixed-size: 1000;
          pango-markup: true;
        }

        # various examples for internal blocks:
        ya_ws: {
        	exec: "YABAR_WORKSPACE";
        	align: "left";
        	fixed-size: 500;
        }
        title: {
        	exec: "xtitle -s";
        	align: "left";
        	fixed-size: 350;
        	type: "persist";
        	foreground-color-rgb:0xeeeeee;
        	underline-color-rgb:0x373b41;
        	overline-color-rgb:0x373b41;
        }
        # another example for an external block
        date: {
        	exec: "date +'%a %d %b, %H:%M'";
        	align: "right";
        	fixed-size: 175;
        	type: "periodic";
        	interval: 1;
        	underline-color-rgb:0xc0b929;
        }
        song:{
        	exec: "YABAR_SONG";
                      align: "center";
        	fixed-size: 200;
        	type: "periodic";
        	internal-option1: "spotify";
        }
      }
    '';
  };
in
  symlinkJoin {
    name = "yabar";

    paths = [ config-file yabar-unstable ];

    buildInputs = [ yabar-unstable makeWrapper ];

    postBuild = ''
      wrapProgram $out/bin/yabar \
        --add-flags "-c ${config-file}/etc/yabar.conf"
    '';
  }
