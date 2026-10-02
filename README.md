# Orchis for CONSTRUCT

[CONSTRUCT](https://github.com/Construct-Linux)'s GTK and GNOME Shell theme: a fork of
[Orchis](https://github.com/vinceliuice/Orchis-theme) by vinceliuice, itself
based on nana-4's [materia-theme](https://github.com/nana-4/materia-theme), trimmed to the one
desktop it themes and drawn in CONSTRUCT's colours.

It builds two themes, `Orchis-Construct-Light` and `Orchis-Construct-Dark`, each with:

- `gtk-3.0` for GTK 3 apps;
- `gtk-4.0` for GTK 4 and libadwaita apps, which read it from `~/.config/gtk-4.0`. The light
  theme's `gtk.css` carries the dark styles under `@media (prefers-color-scheme: dark)`, so one
  copy follows Settings' light/dark switch (GTK >= 4.16);
- `gnome-shell` for GNOME Shell 51, and only 51.

The accent, the surfaces and the success, warning and error colours come from the brand
repository's `palette.toml`, through its generated `palette/construct.scss`, copied here as
`src/_sass/_construct-palette.scss`. The GTK PNG assets are rendered from `src/gtk/assets.svg`
by `src/gtk/render-assets.sh` (Inkscape) and committed.

## Build and install

Requires `bash`, coreutils and `sassc`.

```sh
./install.sh -d /usr/share/themes        # both themes, system-wide
./install.sh -c dark                     # one of them, into ~/.local/share/themes
./install.sh -l                          # also link the light theme's gtk-4.0 for libadwaita
./install.sh -r                          # uninstall
```

`./install.sh --help` lists the tweaks (`--tweaks solid compact primary macos submenu`,
`--round`).

## License

GPL-3.0, as upstream Orchis: see `COPYING`. The Activities icon
(`src/gnome-shell/activities/construct.svg`) is CONSTRUCT's mark, from the brand repository,
under CC-BY-SA-4.0.
