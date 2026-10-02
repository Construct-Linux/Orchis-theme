
REPO_DIR="$(dirname "$(readlink -m "${0}")")"
SRC_DIR="$REPO_DIR/src"

ROOT_UID=0
DEST_DIR=

MY_USERNAME="${SUDO_USER:-$(logname 2> /dev/null || echo "${USER}")}"
MY_HOME=$(getent passwd "${MY_USERNAME}" | cut -d: -f6)

# Destination directory
if [[ "$UID" -eq "$ROOT_UID" ]]; then
  DEST_DIR="/usr/share/themes"
elif [[ -n "$XDG_DATA_HOME" ]]; then
  DEST_DIR="$XDG_DATA_HOME/themes"
elif [[ -d "$HOME/.themes" ]]; then
  DEST_DIR="$HOME/.themes"
elif [[ -d "$HOME/.local/share/themes" ]]; then
  DEST_DIR="$HOME/.local/share/themes"
else
  DEST_DIR="$HOME/.themes"
fi

SASSC_OPT="-M -t expanded"

THEME_NAME=Orchis
THEME_VARIANTS=('' '-Purple' '-Pink' '-Red' '-Orange' '-Yellow' '-Green' '-Teal' '-Grey')
COLOR_VARIANTS=('' '-Light' '-Dark')
SIZE_VARIANTS=('' '-Compact')

icon='-default'

# Check command availability
function has_command() {
  command -v $1 > /dev/null
}

install() {
  local dest="$1"
  local name="$2"
  local theme="$3"
  local color="$4"
  local size="$5"
  local icon="$6"

  if [[ "$color" == '-Dark' ]]; then
    local ELSE_DARK="$color"
    local icon_color='-dark'
    local else_icon_dark="$icon_color"
  fi

  local THEME_DIR="${1}/${2}${3}${4}${5}"

  [[ -d "$THEME_DIR" ]] && rm -rf "$THEME_DIR"

  theme_tweaks && install_theme_color

  echo "Installing '$THEME_DIR'..."

  mkdir -p                                                                                   "$THEME_DIR"
  cp -r "$REPO_DIR/COPYING"                                                                  "$THEME_DIR"

  echo "[Desktop Entry]" >>                                                                  "$THEME_DIR/index.theme"
  echo "Type=X-GNOME-Metatheme" >>                                                           "$THEME_DIR/index.theme"
  echo "Name=${2}${3}${4}${5}" >>                                                        "$THEME_DIR/index.theme"
  echo "Comment=An flat Materia Gtk+ theme based on Elegant Design" >>                       "$THEME_DIR/index.theme"
  echo "Encoding=UTF-8" >>                                                                   "$THEME_DIR/index.theme"
  echo "" >>                                                                                 "$THEME_DIR/index.theme"
  echo "[X-GNOME-Metatheme]" >>                                                              "$THEME_DIR/index.theme"
  echo "GtkTheme=${2}${3}${4}${5}" >>                                                    "$THEME_DIR/index.theme"
  echo "IconTheme=Tela-circle${else_icon_dark:-}" >>                                         "$THEME_DIR/index.theme"
  echo "CursorTheme=Vimix${else_icon_dark:-}" >>                                             "$THEME_DIR/index.theme"
  echo "ButtonLayout=close,minimize,maximize:menu" >>                                        "$THEME_DIR/index.theme"

  mkdir -p                                                                                   "$THEME_DIR/gnome-shell"
  cp -r "$SRC_DIR/gnome-shell/pad-osd.css"                                                   "$THEME_DIR/gnome-shell"
  sassc $SASSC_OPT "$SRC_DIR/gnome-shell/shell-$GS_VERSION/gnome-shell${ELSE_DARK:-}$size.scss" "$THEME_DIR/gnome-shell/gnome-shell.css"

  cp -r "$SRC_DIR/gnome-shell/common-assets"                                                 "$THEME_DIR/gnome-shell/assets"
  cp -r "$SRC_DIR/gnome-shell/assets${ELSE_DARK:-}/"*.svg                                    "$THEME_DIR/gnome-shell/assets"

  if [[ "$primary" == 'true' ]]; then
    cp -r "$SRC_DIR/gnome-shell/theme$theme/checkbox${ELSE_DARK:-}.svg"                "$THEME_DIR/gnome-shell/assets/checkbox.svg"
  fi

  cp -r "$SRC_DIR/gnome-shell/theme$theme/more-results${ELSE_DARK:-}.svg"              "$THEME_DIR/gnome-shell/assets/more-results.svg"
  cp -r "$SRC_DIR/gnome-shell/theme$theme/toggle-on${ELSE_DARK:-}.svg"                 "$THEME_DIR/gnome-shell/assets/toggle-on.svg"

  cp -r "$SRC_DIR/gnome-shell/activities/activities${icon}.svg"                              "$THEME_DIR/gnome-shell/assets/activities.svg"

  cd "$THEME_DIR/gnome-shell"
  ln -s assets/no-events.svg no-events.svg
  ln -s assets/process-working.svg process-working.svg
  ln -s assets/no-notifications.svg no-notifications.svg

  mkdir -p                                                                                   "$THEME_DIR/gtk-3.0"
  cp -r "$SRC_DIR/gtk/assets$theme"                                                    "$THEME_DIR/gtk-3.0/assets"
  cp -r "$SRC_DIR/gtk/scalable"                                                              "$THEME_DIR/gtk-3.0/assets"
  cp -r "$SRC_DIR/gtk/thumbnails/thumbnail$theme${ELSE_DARK:-}.png"                          "$THEME_DIR/gtk-3.0/thumbnail.png"
  sassc $SASSC_OPT "$SRC_DIR/gtk/3.0/gtk$color$size.scss"                                    "$THEME_DIR/gtk-3.0/gtk.css"
  sassc $SASSC_OPT "$SRC_DIR/gtk/3.0/gtk-Dark$size.scss"                                     "$THEME_DIR/gtk-3.0/gtk-dark.css"

  mkdir -p                                                                                   "$THEME_DIR/gtk-4.0"
  cp -r "$SRC_DIR/gtk/assets$theme"                                                    "$THEME_DIR/gtk-4.0/assets"
  cp -r "$SRC_DIR/gtk/scalable"                                                              "$THEME_DIR/gtk-4.0/assets"
  sassc $SASSC_OPT "$SRC_DIR/gtk/4.0/gtk$color$size.scss"                                    "$THEME_DIR/gtk-4.0/gtk.css"
  sassc $SASSC_OPT "$SRC_DIR/gtk/4.0/gtk-Dark$size.scss"                                     "$THEME_DIR/gtk-4.0/gtk-dark.css"

  # libadwaita apps read only ~/.config/gtk-4.0/gtk.css: GTK 4 never loads gtk-dark.css. A light
  # variant's gtk.css carries the dark styles under the colour-scheme media query (GTK >= 4.16),
  # so the apps follow Settings' light/dark switch instead of staying light in a dark session.
  if [[ "$color" != '-Dark' ]]; then
    { echo '@media (prefers-color-scheme: dark) {'; cat "$THEME_DIR/gtk-4.0/gtk-dark.css"; echo '}'; } >> "$THEME_DIR/gtk-4.0/gtk.css"
  fi
}

uninstall() {
  local dest="$1"
  local name="$2"
  local theme="$3"
  local color="$4"
  local size="$5"

  local THEME_DIR="${1}/${2}${3}${4}${5}"

  [[ -d "$THEME_DIR" ]] && rm -rf "$THEME_DIR" && echo -e "Uninstalling "$THEME_DIR" ..."
}

uninstall_link() {
  rm -rf "${HOME}/.config/gtk-4.0/"{assets,gtk.css,gtk-dark.css}
  echo -e "\nRemoving ${HOME}/.config/gtk-4.0 links..."
}

link_libadwaita() {
  local dest="$1"
  local name="$2"
  local theme="$3"
  local color="$4"
  local size="$5"

  local THEME_DIR="${1}/${2}${3}${4}${5}"

  echo -e "\nLink '$THEME_DIR/gtk-4.0' to '${HOME}/.config/gtk-4.0' for libadwaita..."

  [[ ! -d "${HOME}/.config/gtk-4.0" ]] && mkdir -p                              "${HOME}/.config/gtk-4.0"
  rm -rf "${HOME}/.config/gtk-4.0/"{assets,gtk.css,gtk-dark.css}
  ln -sf "${THEME_DIR}/gtk-4.0/assets"                                          "${HOME}/.config/gtk-4.0/assets"
  ln -sf "${THEME_DIR}/gtk-4.0/gtk.css"                                         "${HOME}/.config/gtk-4.0/gtk.css"
  ln -sf "${THEME_DIR}/gtk-4.0/gtk-dark.css"                                    "${HOME}/.config/gtk-4.0/gtk-dark.css"
}

#  Install needed packages
install_package() {
  if [ ! "$(which sassc 2> /dev/null)" ]; then
    echo sassc needs to be installed to generate the css.
    if has_command zypper; then
      sudo zypper in sassc
    elif has_command apt; then
      sudo apt install sassc
    elif has_command apt-get; then
      sudo apt-get install sassc
    elif has_command dnf; then
      sudo dnf install sassc
    elif has_command yum; then
      sudo yum install sassc
    elif has_command pacman; then
      sudo pacman -S --noconfirm sassc
    fi
  fi
}

check_shell() {
  # This fork builds for the one GNOME Shell its desktop runs.
  GS_VERSION="51-0"
}

tweaks_temp() {
  cp -rf $SRC_DIR/_sass/_tweaks.scss $SRC_DIR/_sass/_tweaks-temp.scss
}

change_radio_color() {
  sed -i "/\$check_radio:/s/default/primary/" $SRC_DIR/_sass/_tweaks-temp.scss
}

install_compact_panel() {
  sed -i "/\$panel_style:/s/float/compact/" $SRC_DIR/_sass/_tweaks-temp.scss
}

install_solid() {
  sed -i "/\$opacity:/s/default/solid/" $SRC_DIR/_sass/_tweaks-temp.scss
}

install_black() {
  sed -i "/\$blackness:/s/false/true/" $SRC_DIR/_sass/_tweaks-temp.scss
}

install_mac() {
  sed -i "/\$mac_style:/s/false/true/" $SRC_DIR/_sass/_tweaks-temp.scss
}

round_corner() {
  sed -i "/\$default_corner:/s/12px/${corner}/" $SRC_DIR/_sass/_tweaks-temp.scss
}

install_submenu() {
  sed -i "/\$submenu_style:/s/false/true/" $SRC_DIR/_sass/_tweaks-temp.scss
}

activities_style() {
  sed -i "/\$activities:/s/normal/icon/" $SRC_DIR/_sass/_tweaks-temp.scss
}

accent_type() {
  sed -i "/\$accent_type:/s/default/fixed/" $SRC_DIR/_sass/_tweaks-temp.scss
}

install_theme_color() {
  if [[ "$theme" != '' ]]; then
    case "$theme" in
      -Purple)
        theme_color='purple'
        ;;
      -Pink)
        theme_color='pink'
        ;;
      -Red)
        theme_color='red'
        ;;
      -Orange)
        theme_color='orange'
        ;;
      -Yellow)
        theme_color='yellow'
        ;;
      -Green)
        theme_color='green'
        ;;
      -Teal)
        theme_color='teal'
        ;;
      -Grey)
        theme_color='grey'
        ;;
    esac
    sed -i "/\$theme:/s/default/${theme_color}/" $SRC_DIR/_sass/_tweaks-temp.scss
  fi
}

theme_tweaks() {
  install_package; tweaks_temp

  if [[ "$panel" == "compact" ]] ; then
    install_compact_panel
  fi

  if [[ "$opacity" == "solid" ]] ; then
    install_solid
  fi

  if [[ "$blackness" == "true" ]] ; then
    install_black
  fi

  if [[ "$primary" == "true" ]] ; then
    change_radio_color
  fi

  if [[ "$round" == "true" ]] ; then
    round_corner
  fi

  if [[ "$macstyle" == "true" ]] ; then
    install_mac
  fi

  if [[ "$submenu" == "true" ]] ; then
    install_submenu
  fi

  if [[ "$activities" = "icon" ]] ; then
    activities_style
  fi

  if [[ "$fixed" = "true" ]] ; then
    accent_type
  fi
}

backup_file() {
  if [[ -f "${1}.bak" || -d "${1}.bak" ]]; then
    case "${2}" in
      sudo)
        sudo rm -rf "${1}" ;;
      *)
        rm -rf "${1}" ;;
    esac
  fi

  if [[ -f "${1}" || -d "${1}" ]]; then
    case "${2}" in
      sudo)
        sudo mv -n "${1}"{"",".bak"} ;;
      *)
        mv -n "${1}"{"",".bak"} ;;
    esac
  fi
}

fix_dash_to_dock() {
  local DASH_TO_DOCK_DIR_ROOT="/usr/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com"
  local DASH_TO_DOCK_DIR_HOME="${MY_HOME}/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com"
  local UBUNTU_DOCK_DIR_ROOT="/usr/share/gnome-shell/extensions/ubuntu-dock@ubuntu.com"
  local UBUNTU_DOCK_DIR_HOME="${MY_HOME}/.local/share/gnome-shell/extensions/ubuntu-dock@ubuntu.com"

  if [[ -d "${DASH_TO_DOCK_DIR_HOME}" ]]; then
    backup_file "${DASH_TO_DOCK_DIR_HOME}/stylesheet.css"
  elif [[ -d "${DASH_TO_DOCK_DIR_ROOT}" ]]; then
    backup_file "${DASH_TO_DOCK_DIR_ROOT}/stylesheet.css" "sudo"
  fi

  if [[ -d "${UBUNTU_DOCK_DIR_HOME}" ]]; then
    backup_file "${UBUNTU_DOCK_DIR_HOME}/stylesheet.css"
  elif [[ -d "${UBUNTU_DOCK_DIR_ROOT}" ]]; then
    backup_file "${UBUNTU_DOCK_DIR_ROOT}/stylesheet.css" "sudo"
  fi

  if has_command dbus-launch; then
    dbus-launch dconf write /org/gnome/shell/extensions/dash-to-dock/apply-custom-theme true
  fi
}

install_theme() {
  check_shell

  for theme in "${themes[@]}"; do
    for color in "${colors[@]}"; do
      for size in "${sizes[@]}"; do
        install "${dest:-$DEST_DIR}" "${_name:-$THEME_NAME}" "$theme" "$color" "$size" "$icon"
      done
    done
  done

  local DASH_TO_DOCK_STYLESHEET="$HOME/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com/stylesheet.css"

  if [[ -f "$DASH_TO_DOCK_STYLESHEET" ]]; then
    mv "$DASH_TO_DOCK_STYLESHEET" "$DASH_TO_DOCK_STYLESHEET".bak
  fi
}

uninstall_theme() {
  for theme in "${THEME_VARIANTS[@]}"; do
    for color in "${COLOR_VARIANTS[@]}"; do
      for size in "${SIZE_VARIANTS[@]}"; do
        uninstall "${dest:-$DEST_DIR}" "${_name:-$THEME_NAME}" "$theme" "$color" "$size"
      done
    done
  done

  local DASH_TO_DOCK_STYLESHEET_BAK="$HOME/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com/stylesheet.css.bak"

  if [[ -f "$DASH_TO_DOCK_STYLESHEET_BAK" ]]; then
    mv "$DASH_TO_DOCK_STYLESHEET_BAK" "${DASH_TO_DOCK_STYLESHEET_BAK%.bak}"
  fi
}

clean_theme() {
  if [[ "$DEST_DIR" == "$HOME/.themes" ]]; then
    local dest="$HOME/.local/share/themes"

    for theme in "${themes[@]}"; do
      for color in "${colors[@]}"; do
        for size in "${sizes[@]}"; do
          uninstall "${dest}" "${_name:-$THEME_NAME}" "$theme" "$color" "$size"
        done
      done
    done
  fi
}

link_theme() {
  for theme in "${themes[@]}"; do
    for color in "${lcolors[@]}"; do
      for size in "${sizes[0]}"; do
        link_libadwaita "${dest:-$DEST_DIR}" "${_name:-$THEME_NAME}" "$theme" "$color" "$size"
      done
    done
  done
}
