{ stdenv, lib, callPackage, makeWrapper, symlinkJoin, writeTextFile, themes, config ? {} }:
let
  wm = callPackage ./wm {};

  defaultConfig = {
    general = {
      terminal = "xterm";
      border-width = 1;
    };
    keymap = [
      { keybind = "M-S-r"; command = { restart = {}; }; }
      { keybind = "M-e"; command = { spawn = "dmenu_run"; }; }
    ];
    rules = [
      { selector = { role = "floating"; };
        action = { rect = { x = 0.1; y = 0.0; w = 1.0; h = 0.2; }; }; }
    ];
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

      keymap:
      ${keymap cfg.keymap}

      rules:
      ${rules cfg.rules}
    '';
  };

  keymap = keys :
    lib.concatStringsSep "\n"
      (builtins.map (k: "  * keybind: " + quote k.keybind + "\n    " + keycmd k.command) keys);
  keycmd = cmd :
         if builtins.hasAttr "spawn" cmd then "command: spawn: " + quote cmd.spawn
    else if builtins.hasAttr "restart" cmd then "command: restart"
    else if builtins.hasAttr "promote" cmd then "command: promote"
    else builtins.throw "bad xalt command";

  rules = rls :
    lib.concatStringsSep "\n"
      (builtins.map (s: "  * selector: " + selector s.selector
                    + "\n    action: " + action s.action) rls);
  selector = sel :
         if builtins.hasAttr "role" sel then "role: " + quote sel.role
    else if builtins.hasAttr "name" sel then "name: " + quote sel.name
    else if builtins.hasAttr "class" sel then "class: " + quote sel.class
    else builtins.throw "bad xalt selector";

  action = act :
         if builtins.hasAttr "rect" act then "rect: " + rect act.rect
    else builtins.throw "bad xalt action";

  rect = rect :
    ''{ x: ${toString rect.x}, y: ${toString rect.y}, w: ${toString rect.w}, h: ${toString rect.h} }'';

  xbar-gtk-config = writeTextFile {
    name = "xbar-conf";
    executable = false;
    destination = "/etc/taffybar/taffybar.rc";
    text = ''
      gtk_color_scheme = "black:${cfg.xbar.theme.background}\nwhite:${cfg.xbar.theme.foreground}\ngreen:${cfg.xbar.theme.color2}\nred:${cfg.xbar.theme.color1}"

      style "xbar" {
        font_name    = "${cfg.xbar.font-face} ${cfg.xbar.font-style} ${toString cfg.xbar.font-size}"
        bg[NORMAL]   = @black
        fg[NORMAL]   = @white
        text[NORMAL] = @white
        fg[PRELIGHT] = @green
        bg[PRELIGHT] = @black
      }

      style "active-window" = "xbar" {
        fg[NORMAL] = @green
      }

      style "notification-button" = "xbar" {
        text[NORMAL] = @red
        fg[NORMAL]   = @red
      }

      widget "Taffybar*" style "xbar"
      widget "Taffybar*WindowSwitcher*label" style "active-window"
      widget "*NotificationCloseButton" style "notification-button"
    '';
  };

  quote = s : "\"" + lib.escape ["\""] s + "\"";
in
  symlinkJoin {
    name = "xalt";

    paths = [ wm config-file xbar-gtk-config ];

    buildInputs = [ wm makeWrapper ];

    postBuild = ''
      wrapProgram $out/bin/xalt \
        --add-flags "-c ${config-file}/etc/xalt.conf"
      wrapProgram $out/bin/xbar \
        --set XDG_CONFIG_HOME "$out/etc"
    '';
  }
