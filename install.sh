#! /usr/bin/env bash

REPO_DIR="$(dirname "$(readlink -m "${0}")")"
source "${REPO_DIR}/core.sh"

usage() {
cat << EOF
Usage: $0 [OPTION]...

OPTIONS:
  -d, --dest DIR          Specify destination directory (Default: $DEST_DIR)
  -n, --name NAME         Specify theme name (Default: $THEME_NAME)

  -c, --color VARIANT     Specify color variant(s) [standard|light|dark] (Default: All variants)s)
  -s, --size VARIANT      Specify size variant [standard|compact] (Default: All variants)

  -l, --libadwaita        Link installed Orchis gtk-4.0 theme to config folder for all libadwaita app use Orchis theme

  --tweaks                Specify versions for tweaks [solid|compact|primary|macos|submenu|dock] (Options can mix)
                          1. solid              No transparency panel variant
                          2. compact            No floating panel variant
                          3. primary            Change radio icon checked color to primary theme color (Default is Green)
                          4. macos              Change window buttons to macOS style
                          5. submenu            Set normal submenus color contrast (dark submenu style on dark version)
                          6. dock               Fix style for 'dash-to-dock' or 'ubuntu-dock' extension

  --round                 Change theme round corner border-radius [Input the px value you want] (Suggested: 2px < value < 16px)
                          1. 3px
                          2. 4px
                          3. 5px
                          ...
                          13. 15px


  -r, --remove,
  -u, --uninstall         Uninstall/Remove installed themes

  -h, --help              Show help
EOF
}

colors=()
sizes=()
oocolors=()
osizes=()
lcolors=()

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
      round="true"
      corner="$2"
      echo -e "Change round corner ${corner} value ..."
      shift 2
      ;;
    --tweaks)
      shift
      for variant in $@; do
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
          dock)
            dockfix="true"
            echo -e "\nFix 'dash-to-dock' or 'ubuntu-dock' style ..."
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
          standard)
            colors+=("${COLOR_VARIANTS[0]}")
            lcolors+=("${COLOR_VARIANTS[0]}")
            shift
            ;;
          light)
            colors+=("${COLOR_VARIANTS[1]}")
            lcolors+=("${COLOR_VARIANTS[1]}")
            shift
            ;;
          dark)
            colors+=("${COLOR_VARIANTS[2]}")
            lcolors+=("${COLOR_VARIANTS[2]}")
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
    -s|--size)
      shift
      for variant in "$@"; do
        case "$variant" in
          standard)
            sizes+=("${SIZE_VARIANTS[0]}")
            shift
            ;;
          compact)
            sizes+=("${SIZE_VARIANTS[1]}")
            shift
            ;;
          -*)
            break
            ;;
          *)
            echo "ERROR: Unrecognized size variant '$1'."
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

if [[ "${#sizes[@]}" -eq 0 ]] ; then
  sizes=("${SIZE_VARIANTS[@]}")
fi

if [[ "${#lcolors[@]}" -eq 0 ]] ; then
  lcolors=("${COLOR_VARIANTS[1]}")
fi

if [[ ${remove} == 'true' ]]; then
  if [[ "$libadwaita" == 'true' ]]; then
    uninstall_link
  elif [[ "$all" == 'true' ]]; then
    uninstall_theme && uninstall_link
  else
    uninstall_theme
  fi
else
  if [[ "$libadwaita" == 'true' && "$UID" == "$ROOT_UID" ]]; then
    echo -e "Do not run -l with sudo, that will link libadwaita theme to root folder !"
    exit 0
  fi

  clean_theme
  install_theme

  if [[ "$libadwaita" == 'true' && "$UID" != "$ROOT_UID" ]]; then
    link_theme
  fi

  if [[ "$dockfix" == 'true' ]]; then
    fix_dash_to_dock
  fi
fi

echo
echo "Done."
