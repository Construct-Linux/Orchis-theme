<!-- What this changes and why: what was wrong on screen, what it draws now. -->

## Upstream

Does this restyle a default the palette does not require? Each such change is a conflict on the
next merge from upstream Orchis, so say why it is worth one and link the fork's commit that
makes it.

- [ ] It only recolors or draws what `palette.toml` and THEMING.md ask for, or
- [ ] it restyles an upstream default, because: ... (commit: ...)

## Look

- [ ] `task lint` in brand, with this checkout beside it: colors, the accent's tokens, radii,
      spacing and shadows (C1, C7, G7). A new exception in `lint-forks.toml` says why.
- [ ] `task theme:dev` in os, with `ORCHIS` naming this checkout and the machine `task dev:up`
      runs: the shell's views against the needles in `_output/test/look.html`.
- [ ] `task test:usb` in os, then `task needles:propose`: the needles pull request with every view
      this draws differently. Link it: merging it approves the new look.

Needles PR:
