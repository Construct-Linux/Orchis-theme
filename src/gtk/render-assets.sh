#! /usr/bin/env bash
# Renders the PNGs assets.txt lists from assets.svg into assets/, at 1x and 2x, with Inkscape
# (and optipng when it is there). assets.svg is drawn in Construct's colours: render again after
# changing them, and commit the PNGs, since the build only copies them.

set -e
cd "$(dirname "$(readlink -m "${0}")")"

INKSCAPE="$(command -v inkscape)"
OPTIPNG="$(command -v optipng)" || true

mkdir -p assets

for i in $(cat assets.txt); do
  echo "Rendering 'assets/$i.png' and 'assets/$i@2.png'"
  "$INKSCAPE" --export-id="$i" --export-id-only --export-filename="assets/$i.png" assets.svg >/dev/null
  "$INKSCAPE" --export-id="$i" --export-id-only --export-dpi=192 --export-filename="assets/$i@2.png" assets.svg >/dev/null
  if [[ -n "${OPTIPNG}" ]]; then
    "$OPTIPNG" -o7 -strip all --quiet "assets/$i.png" "assets/$i@2.png"
  fi
done
