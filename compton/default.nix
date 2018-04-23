{ stdenv, lib, makeWrapper, symlinkJoin, writeTextFile, compton-git, config ? {} }:
let
  defaultConfig = {
    # Shadows
    shadow = true;
    no-dnd-shadow = true;
    no-dock-shadow = true;
    clear-shadow = true;
    shadow-radius = 7;
    shadow-offset-x = -7;
    shadow-offset-y = -7;
    shadow-opacity = 0.7;
    shadow-red = 1.0;
    shadow-green = 1.0;
    shadow-blue = 1.0;
    shadow-exclude = [
      "name = 'Notification'"
      "class_g = 'Conky'"
      "class_g ?= 'Notify-osd'"
      "class_g = 'Cairo-clock'"
      "_GTK_FRAME_EXTENTS@:c"
    ];
    xinerama-shadow-crop = true;

    # Opacity
    menu-opacity = 0.8;
    inactive-opacity = 0.8;
    active-opacity = 1.0;
    frame-opacity = 0.7;
    inactive-opacity-override = false;
    alpha-step = 0.06;
    blur-background = false;
    blur-background-frame = false;
    blur-kern = "3x3box";
    blur-background-exclude = [
      "window_type = 'dock'"
      "window_type = 'desktop'"
      "_GTK_FRAME_EXTENTS@:c"
    ];

    # Fading
    fading = true;
    fade-delta = 30;
    fade-in-step = 0.03;
    fade-out-step = 0.03;
    no-fading-openclose = false;
    no-fading-destroyed-argb = false;
    fade-exclude = [ ];

    # Other
    backend = "xrender";
    mark-wmwin-focused = true;
    mark-ovredir-focused = true;
    use-ewmh-active-win = false;
    detect-rounded-corners = true;
    detect-client-opacity = true;
    refresh-rate = 60;
    vsync = "none";
    dbe = false;
    paint-on-overlay = true;
    focus-exclude = [
      "class_g = 'Cairo-clock'"
    ];
    detect-transient = true;
    detect-client-leader = true;
    invert-color-include = [ ];

    glx-no-stencil = false;
    glx-copy-from-front = false;
    glx-use-copysubbuffermesa = false;
    glx-no-rebind-pixmap = false;
    glx-swap-method = "undefined";
    glx-use-gpushader4 = false;

    xrender-sync = false;
    xrender-sync-fence = false;
  };

  cfg = lib.recursiveUpdate defaultConfig config;

  config-file = writeTextFile {
    name = "compton-conf";
    executable = false;
    destination = "/etc/compton.conf";
    text = ''
      shadow = ${ bool cfg.shadow };
      no-dnd-shadow = ${ bool cfg.no-dnd-shadow };
      no-dock-shadow = ${ bool cfg.no-dock-shadow };
      clear-shadow = ${ bool cfg.clear-shadow };
      shadow-radius = ${ int cfg.shadow-radius };
      shadow-offset-x = ${ int cfg.shadow-offset-x };
      shadow-offset-y = ${ int cfg.shadow-offset-y };
      shadow-opacity = ${ float cfg.shadow-opacity };
      shadow-red = ${ float cfg.shadow-red };
      shadow-green = ${ float cfg.shadow-green };
      shadow-blue = ${ float cfg.shadow-blue };
      shadow-exclude = ${ list cfg.shadow-exclude };
      xinerama-shadow-crop = ${ bool cfg.xinerama-shadow-crop };

      menu-opacity = ${ float cfg.menu-opacity };
      inactive-opacity = ${ float cfg.inactive-opacity };
      active-opacity = ${ float cfg.active-opacity };
      frame-opacity = ${ float cfg.frame-opacity };
      inactive-opacity-override = ${ bool cfg.inactive-opacity-override };
      alpha-step = ${ float cfg.alpha-step };
      blur-background = ${ bool cfg.blur-background };
      blur-background-frame = ${ bool cfg.blur-background-frame };
      blur-kern = ${ quote cfg.blur-kern };
      blur-background-exclude = ${ list cfg.blur-background-exclude };

      fading = ${ bool cfg.fading };
      fade-delta = ${ int cfg.fade-delta };
      fade-in-step = ${ float cfg.fade-in-step };
      fade-out-step = ${ float cfg.fade-out-step };
      no-fading-openclose = ${ bool cfg.no-fading-openclose };
      no-fading-destroyed-argb = ${ bool cfg.no-fading-destroyed-argb };
      fade-exclude = ${ list cfg.fade-exclude };

      backend = ${ quote cfg.backend };
      mark-wmwin-focused = ${ bool cfg.mark-wmwin-focused };
      mark-ovredir-focused = ${ bool cfg.mark-ovredir-focused };
      use-ewmh-active-win = ${ bool cfg.use-ewmh-active-win };
      detect-rounded-corners = ${ bool cfg.detect-rounded-corners };
      detect-client-opacity = ${ bool cfg.detect-client-opacity };
      refresh-rate = ${ int cfg.refresh-rate };
      vsync = ${ quote cfg.vsync };
      dbe = ${ bool cfg.dbe };
      paint-on-overlay = ${ bool cfg.paint-on-overlay };
      focus-exclude = ${ list cfg.focus-exclude };
      detect-transient = ${ bool cfg.detect-transient };
      detect-client-leader = ${ bool cfg.detect-client-leader };
      invert-color-include = ${ list cfg.invert-color-include };

      glx-no-stencil = ${ bool cfg.glx-no-stencil };
      glx-copy-from-front = ${ bool cfg.glx-copy-from-front };
      glx-use-copysubbuffermesa = ${ bool cfg.glx-use-copysubbuffermesa };
      glx-no-rebind-pixmap = ${ bool cfg.glx-no-rebind-pixmap };
      glx-swap-method = ${ quote cfg.glx-swap-method };
      glx-use-gpushader4 = ${ bool cfg.glx-use-gpushader4 };

      xrender-sync = ${ bool cfg.xrender-sync };
      xrender-sync-fence = ${ bool cfg.xrender-sync };
    '';
  };

  bool = b : if b then "true" else "false";
  int = x : builtins.toString x;
  float = x : builtins.toString x;
  list = xs : "[" + builtins.concatStringsSep ", " (builtins.map quote xs) + "]";
  quote = s : "\"" + lib.escape ["\""] s + "\"";

in
  symlinkJoin {
    name = "compton";

    paths = [ config-file compton-git ];

    buildInputs = [ compton-git makeWrapper ];

    postBuild = ''
      wrapProgram $out/bin/compton \
        --add-flags "--config=${config-file}/etc/compton.conf"
    '';
  }
