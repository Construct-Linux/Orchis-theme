#! /usr/bin/env bash
#
# Builds Orchis-Construct-Light and Orchis-Construct-Dark: GTK 3, GTK 4 (libadwaita) and
# GNOME Shell 51 styles in CONSTRUCT's colours.

set -eo pipefail

REPO_DIR="$(dirname "$(readlink -m "${0}")")"
SRC_DIR="$REPO_DIR/src"

THEME_NAME=Orchis-Construct
COLOR_VARIANTS=('-Light' '-Dark')
SASSC_OPT=('-M' '-t' 'expanded')

if [[ "$UID" -eq 0 ]]; then
  DEST_DIR="/usr/share/themes"
elif [[ -n "$XDG_DATA_HOME" ]]; then
  DEST_DIR="$XDG_DATA_HOME/themes"
else
  DEST_DIR="$HOME/.local/share/themes"
fi

usage() {
cat << EOF
Usage: $0 [OPTION]...

OPTIONS:
  -d, --dest DIR          Destination directory (Default: $DEST_DIR)
  -c, --color VARIANT     Color variant(s) [light|dark] (Default: both)

  -r, --remove,
  -u, --uninstall         Uninstall the themes

  -h, --help              Show help
EOF
}

install() {
  local dest="$1"
  local name="$2"
  local color="$3"
  local THEME_DIR="$dest/$name$color"

  [ -d "$THEME_DIR" ]] && rm -rf "$THEME_DIR"

  echo "Installing '$THEME_DIR'..."

  mkdir -p                                                                    "$THEME_DIR"
  cp -r "$REPO_DIR/COPYING"                                                   "$THEME_DIR"

  cat > "$THEME_DIR/index.theme" << EOF
[Desktop Entry]
Type=X-GNOME-Metatheme
Name=$name$color
Comment=Orchis, a flat Material theme, in CONSTRUCT's colours
Encoding=UTF-8

[X-GNOME-Metatheme]
GtkTheme=$name$color
ButtonLayout=close,minimize,maximize:menu
EOF

  # The shell takes the dark variant only: the user-theme extension loads Orchis-Construct-Dark,
  # whatever Settings' light/dark switch says.
  if [[ "$color" == '-Dark' ]]; then
    mkdir -p                                                                  "$THEME_DIR/gnome-shell"
    sassc "${SASSC_OPT[@]}" "$SRC_DIR/gnome-shell/shell-51-0/gnome-shell.scss" "$THEME_DIR/gnome-shell/gnome-shell.css"
    cp -r "$SRC_DIR/gnome-shell/assets"                                       "$THEME_DIR/gnome-shell/assets"
    cp -r "$SRC_DIR/gnome-shell/activities/construct.svg"                     "$THEME_DIR/gnome-shell/assets/activities.svg"
  fi

  mkdir -p                                                                    "$THEME_DIR/gtk-3.0"
  cp -r "$SRC_DIR/gtk/assets"                                                 "$THEME_DIR/gtk-3.0/assets"
  cp -r "$SRC_DIR/gtk/scalable"                                               "$THEME_DIR/gtk-3.0/assets"
  sassc "${SASSC_OPT[@]}" "$SRC_DIR/gtk/3.0/gtk$color.scss"                   "$THEME_DIR/gtk-3.0/gtk.css"
  sassc "${SASSC_OPT[@]}" "$SRC_DIR/gtk/3.0/gtk-Dark.scss"                    "$THEME_DIR/gtk-3.0/gtk-dark.css"

  mkdir -p                                                                    "$THEME_DIR/gtk-4.0"
  cp -r "$SRC_DIR/gtk/assets"                                                 "$THEME_DIR/gtk-4.0/assets"
  cp -r "$SRC_DIR/gtk/scalable"                                               "$THEME_DIR/gtk-4.0/assets"
  # GTK 4's selection-mode checks are the symbolic SVGs; the PNGs are GTK 3's.
  rm -f "$THEME_DIR/gtk-4.0/assets/selectionmode-checkbox-"*
  sassc "${SASSC_OPT[@]}" "$SRC_DIR/gtk/4.0/gtk$color.scss"                   "$THEME_DIR/gtk-4.0/gtk.css"
  sassc "${SASSC_OPT[@]}" "$SRC_DIR/gtk/4.0/gtk-Dark.scss"                    "$THEME_DIR/gtk-4.0/gtk-dark.css"

  # libadwaita apps read only ~/.config/gtk-4.0/gtk.css: GTK 4 never loads gtk-dark.css. A light
  # variant's gtk.css holds both schemes, the rules they differ in under the colour-scheme media
  # query (GTK >= 4.16), so the apps follow Settings' light/dark switch instead of staying light
  # in a dark session.
  if [[ "$color" != '-Dark' ]]; then
    mv "$THEME_DIR/gtk-4.0/gtk.css" "$THEME_DIR/gtk-4.0/gtk-light.css"
    awk -f "$SRC_DIR/gtk/color-schemes.awk" "$THEME_DIR/gtk-4.0/gtk-light.css" \
      "$THEME_DIR/gtk-4.0/gtk-dark.css" > "$THEME_DIR/gtk-4.0/gtk.css"
    rm "$THEME_DIR/gtk-4.0/gtk-light.css"
  fi
}

colors=()

while [[ "$#" -gt 0 ]]; do
  case "${1:-}" in
    -d|--dest)
      dest="$2"
      mkdir -p "$dest"
      shift 2
      ;;
    -r|--remove|-u|--uninstall)
      remove="true"
      shift
      ;;
    -c|--color)
      shift
      for variant in "$@"; do
        case "$variant" in
          light)
            colors+=("${COLOR_VARIANTS[0]}")
            shift
            ;;
          dark)
            colors+=("${COLOR_VARIANTS[1]}")
            shift
            ;;
          -*)
            break
            ;;
          *)
            echo "ERROR: Unrecognized color variant '$1'."
            echo "Try '$0 --help' for more information."
            exit 1
            ;;
        esac
      done
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unrecognized installation option '$1'."
      echo "Try '$0 --help' for more information."
      exit 1
      ;;
  esac
done

if [[ "${#colors[@]}" -eq 0 ]] ; then
  colors=("${COLOR_VARIANTS[@]}")
fi

dest="${dest:-$DEST_DIR}"
name="$THEME_NAME"

if [[ "$remove" == 'true' ]]; then
  for color in "${COLOR_VARIANTS[@]}"; do
    if [[ -d "$dest/$name$color" ]]; then
      rm -rf "$dest/$name$color"
      echo -e "Uninstalling $dest/$name$color ..."
    fi
  done
else
  if ! command -v sassc > /dev/null; then
    echo "ERROR: 'sassc' needs to be installed to generate the CSS."
    exit 1
  fi

  for color in "${colors[@]}"; do
    install "$dest" "$name" "$color"
  done
fi

echo
echo "Done."
