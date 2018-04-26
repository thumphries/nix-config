# nix-config

Desktop configuration as code.

Using Nix as a configuration layer to stitch together a deterministic, 
immutable desktop environment from a variety of tools. It mostly consists of
`makeWrapper`, `symlinkJoin`, templated scripts and configuration, and a bunch 
of my own Nix packages. It does not and will not require NixOS, just Nix on Linux.
The top-level `default.nix` is a good place to start.

This is not immediately usable by others due to the private submodule containing
various fonts and programs that I do not have the right to distribute. You could
hack around this pretty easily if you really wanted to. Once you have done so,
deploying is as simple as:

```sh
nix-env -f default.nix -i nix-config
echo "xinitrc" >> $HOME/.xinitrc
```

... and logging in with `startx`, `SLiM`, or what ever have you.

I am doing this to learn Nix while addressing a personal frustration, namely the
effort involved in customising a Linux desktop and keeping changes + adhoc software
synchronised between multiple machines. The Nix code is likely not idiomatic.
File pull requests if you care. Don't file issues.
