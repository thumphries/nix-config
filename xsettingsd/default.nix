{ stdenv, lib, makeWrapper, symlinkJoin, writeTextFile, xsettingsd, config ? {} }:
let
  defaultConfig = {
    gdk-unscaled-dpi = 98304;
    gdk-window-scaling-factor = 1;

    gtk-cursor-theme-name = "Adwaita";
    gtk-enable-primary-paste = true;
    gtk-font-face = "Cantarell";
    gtk-font-size = 11;
    gtk-key-theme-name = "Emacs";

    net-cursor-blink = true;
    net-cursor-blink-time = 1200;
    net-icon-theme-name = "Adwaita";
    net-theme-name = "Adwaita";

    xft-antialias = true;
    xft-dpi = 98304;
    xft-hint-style = "hintslight";
    xft-hinting = true;
    xft-rgba = "rgb";
  };

  cfg = lib.recursiveUpdate defaultConfig config;

  config-file = writeTextFile {
    name = "xsettingsd-conf";
    executable = false;
    destination = "/etc/xsettingsd.conf";
    text = ''
      Gdk/UnscaledDPI ${ toString cfg.gdk-unscaled-dpi }
      Gdk/WindowScalingFactor ${ toString cfg.gdk-window-scaling-factor }

      Gtk/CursorThemeName ${ quote cfg.gtk-cursor-theme-name }
      Gtk/EnablePrimaryPaste ${ bool cfg.gtk-enable-primary-paste }
      Gtk/FontName ${ quote (cfg.gtk-font-face + " " + (toString cfg.gtk-font-size)) }
      Gtk/KeyThemeName ${ quote cfg.gtk-key-theme-name }

      Net/CursorBlink ${ bool cfg.net-cursor-blink }
      Net/CursorBlinkTime ${ toString cfg.net-cursor-blink-time }
      Net/IconThemeName ${ quote cfg.net-icon-theme-name }
      Net/ThemeName ${ quote cfg.net-theme-name }

      Xft/Antialias ${ bool cfg.xft-antialias }
      Xft/DPI ${ toString cfg.xft-dpi }
      Xft/HintStyle ${ quote cfg.xft-hint-style }
      Xft/Hinting ${ bool cfg.xft-hinting }
      Xft/RGBA ${ quote cfg.xft-rgba }
    '';
  };

  bool = b : if b then "1" else "0";
  quote = s : "\"" + lib.escape ["\""] s + "\"";

in
  symlinkJoin {
    name = "xsettingsd";

    paths = [ config-file xsettingsd ];

    buildInputs = [ xsettingsd makeWrapper ];

    postBuild = ''
      wrapProgram $out/bin/xsettingsd \
        --add-flags "--config=${config-file}/etc/xsettingsd.conf"
    '';
  }
