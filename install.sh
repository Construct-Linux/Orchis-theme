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
  -n, --name NAME         Theme name (Default: $THEME_NAME)
  -c, --color VARIANT     Color variant(s) [light|dark] (Default: both)

  -l, --libadwaita        Link the installed gtk-4.0 theme into ~/.config/gtk-4.0, where
                          libadwaita apps read it (the first -c variant, Default: light,
                          which carries the dark styles for a dark session)

  --tweaks TWEAK...       [solid|compact|primary|macos|submenu] (Options can mix)
                          1. solid              No transparency panel variant
                          2. compact            No floating panel variant
                          3. primary            Change radio icon checked color to primary theme color (Default is Green)
                          4. macos              Change window buttons to macOS style
                          5. submenu            Set normal submenus color contrast (dark submenu style on dark version)

  --round PX              Change theme round corner border-radius (Suggested: 2px < value < 16px)

  -r, --remove,
  -u, --uninstall         Uninstall the themes (with -l, only the ~/.config/gtk-4.0 links)

  -h, --help              Show help
EOF
}

# Every tweak edits a copy of _tweaks.scss, which _colors.scss and _variables.scss import.
theme_tweaks() {
  local tweaks="$SRC_DIR/_sass/_tweaks-temp.scss"

  cp -f "$SRC_DIR/_sass/_tweaks.scss" "$tweaks"
  [[ "$panel" == "compact" ]] && sed -i "/\$panel_style:/s/float/compact/" "$tweaks"
  [[ "$opacity" == "solid" ]] && sed -i "/\$opacity:/s/default/solid/" "$tweaks"
  [[ "$primary" == "true" ]] && sed -i "/\$check_radio:/s/default/primary/" "$tweaks"
  [[ -n "$corner" ]] && sed -i "/\$default_corner:/s/12px/${corner}/" "$tweaks"
  [[ "$macstyle" == "true" ]] && sed -i "/\$mac_style:/s/false/true/" "$tweaks"
  [[ "$submenu" == "true" ]] && sed -i "/\$submenu_style:/s/false/true/" "$tweaks"
  return 0
}

install() {
  local dest="$1"
  local name="$2"
  local color="$3"
  local THEME_DIR="$dest/$name$color"
  local ELSE_DARK=

  [[ "$color" == '-Dark' ]] && ELSE_DARK="$color"
  [[ -d "$THEME_DIR" ]] && rm -rf "$THEME_DIR"

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

  mkdir -p                                                                    "$THEME_DIR/gnome-shell"
  sassc "${SASSC_OPT[@]}" "$SRC_DIR/gnome-shell/shell-51-0/gnome-shell$ELSE_DARK.scss" "$THEME_DIR/gnome-shell/gnome-shell.css"

  cp -r "$SRC_DIR/gnome-shell/common-assets"                                  "$THEME_DIR/gnome-shell/assets"
  cp -r "$SRC_DIR/gnome-shell/assets$ELSE_DARK/"*.svg                         "$THEME_DIR/gnome-shell/assets"

  if [[ "$primary" == 'true' ]]; then
    cp -r "$SRC_DIR/gnome-shell/theme/checkbox$ELSE_DARK.svg"                 "$THEME_DIR/gnome-shell/assets/checkbox.svg"
  fi

  cp -r "$SRC_DIR/gnome-shell/theme/toggle-on$ELSE_DARK.svg"                  "$THEME_DIR/gnome-shell/assets/toggle-on.svg"
  cp -r "$SRC_DIR/gnome-shell/activities/construct.svg"                       "$THEME_DIR/gnome-shell/assets/activities.svg"

  mkdir -p                                                                    "$THEME_DIR/gtk-3.0"
  cp -r "$SRC_DIR/gtk/assets"                                                 "$THEME_DIR/gtk-3.0/assets"
  cp -r "$SRC_DIR/gtk/scalable"                                               "$THEME_DIR/gtk-3.0/assets"
  sassc "${SASSC_OPT[@]}" "$SRC_DIR/gtk/3.0/gtk$color.scss"                   "$THEME_DIR/gtk-3.0/gtk.css"
  sassc "${SASSC_OPT[@]}" "$SRC_DIR/gtk/3.0/gtk-Dark.scss"                    "$THEME_DIR/gtk-3.0/gtk-dark.css"

  mkdir -p                                                                    "$THEME_DIR/gtk-4.0"
  cp -r "$SRC_DIR/gtk/assets"                                                 "$THEME_DIR/gtk-4.0/assets"
  cp -r "$SRC_DIR/gtk/scalable"                                               "$THEME_DIR/gtk-4.0/assets"
  sassc "${SASSC_OPT[@]}" "$SRC_DIR/gtk/4.0/gtk$color.scss"                   "$THEME_DIR/gtk-4.0/gtk.css"
  sassc "${SASSC_OPT[@]}" "$SRC_DIR/gtk/4.0/gtk-Dark.scss"                    "$THEME_DIR/gtk-4.0/gtk-dark.css"

  # libadwaita apps read only ~/.config/gtk-4.0/gtk.css: GTK 4 never loads gtk-dark.css. A light
  # variant's gtk.css carries the dark styles under the colour-scheme media query (GTK >= 4.16),
  # so the apps follow Settings' light/dark switch instead of staying light in a dark session.
  if [[ "$color" != '-Dark' ]]; then
    { echo '@media (prefers-color-scheme: dark) {'; cat "$THEME_DIR/gtk-4.0/gtk-dark.css"; echo '}'; } >> "$THEME_DIR/gtk-4.0/gtk.css"
  fi
}

link_libadwaita() {
  local THEME_DIR="$1/$2$3"
  local config="$HOME/.config/gtk-4.0"

  echo -e "\nLink '$THEME_DIR/gtk-4.0' to '$config' for libadwaita..."

  mkdir -p "$config"
  rm -rf "$config/"{assets,gtk.css,gtk-dark.css}
  ln -sf "$THEME_DIR/gtk-4.0/assets"                                          "$config/assets"
  ln -sf "$THEME_DIR/gtk-4.0/gtk.css"                                         "$config/gtk.css"
  ln -sf "$THEME_DIR/gtk-4.0/gtk-dark.css"                                    "$config/gtk-dark.css"
}

colors=()

while [[ "$#" -gt 0 ]]; do
  case "${1:-}" in
    -d|--dest)
      dest="$2"
      mkdir -p "$dest"
      shift 2
      ;;
    -n|--name)
      _name="$2"
      shift 2
      ;;
    -r|--remove|-u|--uninstall)
      remove="true"
      shift
      ;;
    -l|--libadwaita)
      libadwaita="true"
      shift
      ;;
    --round)
      corner="$2"
      echo -e "Change round corner ${corner} value ..."
      shift 2
      ;;
    --tweaks)
      shift
      for variant in "$@"; do
        case "$variant" in
          solid)
            opacity="solid"
            echo -e "Install solid version ..."
            shift
            ;;
          compact)
            panel="compact"
            echo -e "Install compact panel version ..."
            shift
            ;;
          primary)
            primary="true"
            echo "Change radio and check assets color ..."
            shift
            ;;
          macos)
            macstyle="true"
            echo -e "Install macOS style window button version ..."
            shift
            ;;
          submenu)
            submenu="true"
            echo -e "Install with themed sub-menus ..."
            shift
            ;;
          -*)
            break
            ;;
          *)
            echo "ERROR: Unrecognized tweaks variant '$1'."
            echo "Try '$0 --help' for more information."
            exit 1
            ;;
        esac
      done
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
name="${_name:-$THEME_NAME}"

if [[ "$remove" == 'true' ]]; then
  if [[ "$libadwaita" == 'true' ]]; then
    rm -rf "$HOME/.config/gtk-4.0/"{assets,gtk.css,gtk-dark.css}
    echo -e "\nRemoving $HOME/.config/gtk-4.0 links..."
  else
    for color in "${COLOR_VARIANTS[@]}"; do
      if [[ -d "$dest/$name$color" ]]; then
        rm -rf "$dest/$name$color"
        echo -e "Uninstalling $dest/$name$color ..."
      fi
    done
  fi
else
  if [[ "$libadwaita" == 'true' && "$UID" -eq 0 ]]; then
    echo -e "Do not run -l with sudo, that will link libadwaita theme to root folder !"
    exit 1
  fi

  if ! command -v sassc > /dev/null; then
    echo "ERROR: 'sassc' needs to be installed to generate the CSS."
    exit 1
  fi

  theme_tweaks

  for color in "${colors[@]}"; do
    install "$dest" "$name" "$color"
  done

  if [[ "$libadwaita" == 'true' ]]; then
    link_libadwaita "$dest" "$name" "${colors[0]}"
  fi
fi

echo
echo "Done."
