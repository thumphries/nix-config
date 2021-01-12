let
  pinned = pin:
    let
      path = ./. + pin;
      json = builtins.fromJSON (builtins.readFile path);
    in
      import ((import <nixpkgs> { }).fetchFromGitHub {
        owner = "NixOS";
        repo = "nixpkgs";
        inherit (json) rev sha256;
      }) { config = { }; };

  nixpkgs = pinned "/nixpkgs.json";

  gocmds = nixpkgs.pkgs.callPackage ./gocmds {
    goinstalls = [
      {
        name = "ghq";
        package = "github.com/motemen/ghq";
        revision = "7ba9b5f82952dc930f289262a2df7bafb6bd53bf";
        sha = "2b4a72eb1f387f9a6246d830105d8156bf1fbc26";
        binaries = ["ghq"];
      }
      {
        name = "wtf";
        package = "github.com/wtfutil/wtf";
        revision = "5291a31afd9a525342ab62896423a00e06f3811f";
        sha = "49de074784f3b08a764bbe453db893e7d7dfe78a";
        binaries = ["wtf"];
      }
    ];
  };

  # May require 'git config --global core.sshCommand ssh'
  sshWrapper = nixpkgs.pkgs.writeTextFile {
    name = "ssh-wrapper";
    executable = true;
    destination = "/bin/ssh";
    text = ''
#!/bin/sh -eu
BINARY_SSH=/usr/bin/ssh ssh-ident "$@"
    '';
  };
in
  with nixpkgs;
  pkgs.buildEnv rec {
    name = "thumphries-min";
    meta.priority = 8;
    paths = [
      pkgs.glibcLocales

      pkgs.emacs

      pkgs.bat
      pkgs.fd
      pkgs.exa
      pkgs.ripgrep
      pkgs.sd
      pkgs.du-dust
      pkgs.tokei

      pkgs.cacert
      pkgs.git
      pkgs.git-lfs
      pkgs.tig

      pkgs.ssh-ident
      sshWrapper

      pkgs.direnv
      pkgs.fzf

      pkgs.jq
      pkgs.jid
      pkgs.pup

      gocmds

      pkgs.shellcheck

      pkgs.imagemagick

      pkgs.ghc

      pkgs.awscli
      pkgs.aws-vault
      pkgs.python
    ];
  }
