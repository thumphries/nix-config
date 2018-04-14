{ stdenv, makeWrapper, symlinkJoin, writeTextFile, termite, themes, config ? {} }:
let
  defaultConfig = {
    font-face = "Monospace";
    font-style = "Regular";
    font-size = 11;
    allow-bold = true;
    scrollbar = true;
    scrollback = 10000;
    audible-bell = true;
    clickable-url = true;
    theme = themes.Novel;
  };

  cfg = defaultConfig // config;

  config-file = writeTextFile {
    name = "termite-conf";
    executable = false;
    destination = "/etc/termite.conf";
    text = ''
      [options]
      font = ${ cfg.font-face } ${ toString cfg.font-size }
      allow_bold = ${ bool cfg.allow-bold }
      scrollbar = ${ bool cfg.scrollbar }
      audible_bell = ${ bool cfg.audible-bell }
      scrollback_lines = ${ toString cfg.scrollback }
      clickable_url = ${ bool cfg.clickable-url }

      [colors]
      foreground = ${ cfg.theme.foreground }
      background = ${ cfg.theme.background }
      color0     = ${ cfg.theme.color0  }
      color1     = ${ cfg.theme.color1  }
      color2     = ${ cfg.theme.color2  }
      color3     = ${ cfg.theme.color3  }
      color4     = ${ cfg.theme.color4  }
      color5     = ${ cfg.theme.color5  }
      color6     = ${ cfg.theme.color6  }
      color7     = ${ cfg.theme.color7  }
      color8     = ${ cfg.theme.color8  }
      color9     = ${ cfg.theme.color9  }
      color10    = ${ cfg.theme.color10 }
      color11    = ${ cfg.theme.color11 }
      color12    = ${ cfg.theme.color12 }
      color13    = ${ cfg.theme.color13 }
      color14    = ${ cfg.theme.color14 }
      color15    = ${ cfg.theme.color15 }

      [hints]
      font = ${ cfg.font-face } ${ cfg.font-style } ${ toString cfg.font-size }
      foreground = ${ cfg.theme.foreground }
      background = ${ cfg.theme.background }
    '';
  };

  bool = b : if b then "true" else "false";
in
  symlinkJoin {
    name = "termite-config";

    paths = [ config-file termite ];

    buildInputs = [ termite makeWrapper ];

    postBuild = ''
      wrapProgram $out/bin/termite \
        --add-flags "--config=${config-file}/etc/termite.conf"
    '';
  }
