{ nixpkgs, stdenv, lib, callPackage, makeWrapper, symlinkJoin, writeTextFile, themes, config ? {} }:
let
  wm = callPackage ./wm { nixpkgs = nixpkgs; };

  defaultConfig = {
    general = {
      terminal = "xterm";
      border-width = 1;
      border-color = "#000000";
      border-color-focused = "#FEFEFE";
    };
    keymap = [
      { keybind = "M-S-r"; command = { restart = {}; }; }
      { keybind = "M-e"; command = { spawn = "dmenu_run"; }; }
    ];
    rules = [
      { selector = { role = "floating"; };
        action = { rect = { x = 0.1; y = 0.0; w = 1.0; h = 0.2; }; }; }
    ];
    scratchpads = [];
    xbar = {
      font-face = "Monospace";
      font-style = "";
      font-size = 14;
      theme = themes.novel;
    };
  };

  cfg = lib.recursiveUpdate defaultConfig config;

  config-file = writeTextFile {
    name = "xalt-conf";
    executable = false;
    destination = "/etc/xalt.conf";
    text = ''
      general:
        terminal: ${quote cfg.general.terminal}
        border-width: ${toString cfg.general.border-width}
        border-color: ${quote cfg.general.border-color}
        border-color-focused: ${quote cfg.general.border-color-focused}

      keymap:
      ${keymap cfg.keymap}

      rules:
      ${rules cfg.rules}

      scratchpads:
      ${pads cfg.scratchpads}
    '';
  };

  keymap = keys :
    lib.concatStringsSep "\n"
      (builtins.map (k: "  * keybind: " + quote k.keybind + "\n    " + keycmd k.command) keys);
  keycmd = cmd :
         if builtins.hasAttr "spawn" cmd then "command: spawn: " + quote cmd.spawn
    else if builtins.hasAttr "restart" cmd then "command: restart"
    else if builtins.hasAttr "promote" cmd then "command: promote"
    else if builtins.hasAttr "pin" cmd then "command: pin"
    else if builtins.hasAttr "unpin" cmd then "command: unpin"
    else if builtins.hasAttr "magnify" cmd then "command: magnify"
    else if builtins.hasAttr "fullscreen" cmd then "command: fullscreen"
    else if builtins.hasAttr "float" cmd then "command: float"
    else if builtins.hasAttr "sink" cmd then "command: sink"
    else if builtins.hasAttr "scratch" cmd then "command: scratch: " + quote cmd.scratch
    else builtins.throw "bad xalt command";

  rules = rls :
    lib.concatStringsSep "\n"
      (builtins.map (s: "  * selector: " + selector s.selector
                    + "\n    action: " + action s.action) rls);

  pads = pds :
    lib.concatStringsSep "\n"
      (builtins.map (p: "  * name: " + quote p.name
                    + "\n    command: " + quote p.command
                    + "\n    selector: " + selector p.selector
                    + "\n    action: " + action p.action) pds);

  selector = sel :
         if builtins.hasAttr "role" sel then "role: " + quote sel.role
    else if builtins.hasAttr "name" sel then "name: " + quote sel.name
    else if builtins.hasAttr "class" sel then "class: " + quote sel.class
    else builtins.throw "bad xalt selector";

  action = act :
         if builtins.hasAttr "rect" act then "rect: " + rect act.rect
    else if builtins.hasAttr "tile" act then "tile"
    else builtins.throw "bad xalt action";

  rect = rect :
    ''{ x: ${toString rect.x}, y: ${toString rect.y}, w: ${toString rect.w}, h: ${toString rect.h} }'';

  xbar-css-config = writeTextFile {
    name = "xbar-css";
    executable = false;
    destination = "/etc/taffybar/taffybar.css";
    text = ''
      @define-color transparent rgba(0.0, 0.0, 0.0, 0.0);
      @define-color bg ${cfg.xbar.theme.background};
      @define-color fg ${cfg.xbar.theme.foreground};
      @define-color black ${cfg.xbar.theme.color0};
      @define-color red ${cfg.xbar.theme.color1};
      @define-color green ${cfg.xbar.theme.color2};
      @define-color yellow ${cfg.xbar.theme.color3};
      @define-color blue ${cfg.xbar.theme.color4};
      @define-color magenta ${cfg.xbar.theme.color5};
      @define-color cyan ${cfg.xbar.theme.color6};
      @define-color white ${cfg.xbar.theme.color7};

      @define-color taffy-blue @blue;

      @define-color active-window-color @white;
      @define-color urgent-window-color @taffy-blue;
      @define-color font-color @white;
      @define-color menu-background-color @white;
      @define-color menu-font-color @black;

      /* Top-level bar config */
      .taffy-window * {
        font-family: "${cfg.xbar.font-face}";
        font-size: ${toString cfg.xbar.font-size}pt;
        color: @fg;
      }

      .taffy-box {
        border-radius: 0px;
        background-color: @bg;
      }

      /* Workspaces styling */

      .workspace-label {
        padding-right: 6px;
        padding-left: 4px;
      }

      .active {
        color: @yellow;
      }

      .empty {
        opacity: 0.5;
      }
    '';
  };

  quote = s : "\"" + lib.escape ["\""] s + "\"";
in
  symlinkJoin {
    name = "xalt";

    paths = [ wm config-file xbar-css-config ];

    buildInputs = [ wm makeWrapper ];

    postBuild = ''
      wrapProgram $out/bin/xalt \
        --add-flags "-c ${config-file}/etc/xalt.conf"
      wrapProgram $out/bin/xbar \
        --set XDG_CONFIG_HOME "$out/etc"
    '';
  }
