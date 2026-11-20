#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "$0")/.." && pwd)
resource_base=/usr/share/sushi/org.gnome.NautilusPreviewer
previewer=/usr/libexec/org.gnome.NautilusPreviewer
resource_root=/org/gnome/NautilusPreviewer
xdg_data=${XDG_DATA_HOME:-"$HOME/.local/share"}
resource_dir="$xdg_data/dolphin-sushi/headerless"

if [[ ! -x "$previewer" ]]; then
    printf 'Install GNOME Sushi 51.2 first.\n' >&2
    exit 1
fi
stage=$(mktemp -d)
trap 'rm -rf -- "$stage"' EXIT
for resource in ui/mainWindow.ui js/core/mainWindow.js js/viewers/pdf.js; do
    case "$resource" in ui/*) bundle=data ;; *) bundle=src ;; esac
    mkdir -p -- "$stage/$(dirname -- "$resource")"
    gresource extract "$resource_base.$bundle.gresource" "$resource_root/$resource" >"$stage/$resource"
done
# Check every change before replacing files from an existing installation.
patch --batch --forward --fuzz=0 -p1 -d "$stage" -i "$repo_dir/patches/sushi-51.2-preview.patch"
for resource in ui/mainWindow.ui js/core/mainWindow.js js/viewers/pdf.js; do
    install -Dm644 "$stage/$resource" "$resource_dir/$resource"
done
mkdir -p -- "$HOME/.local/bin" "$xdg_data/dbus-1/services"
cat >"$stage/sushi-headerless-service" <<'WRAPPER'
#!/usr/bin/env bash
export G_RESOURCE_OVERLAYS="/org/gnome/NautilusPreviewer=${XDG_DATA_HOME:-$HOME/.local/share}/dolphin-sushi/headerless"
exec /usr/libexec/org.gnome.NautilusPreviewer "$@"
WRAPPER
install -m755 "$stage/sushi-headerless-service" "$HOME/.local/bin/sushi-headerless-service"
printf '[D-BUS Service]\nName=org.gnome.NautilusPreviewer\nExec="%s/.local/bin/sushi-headerless-service"\n' "$HOME" >"$xdg_data/dbus-1/services/org.gnome.NautilusPreviewer.service"
printf 'Installed Sushi preview overrides. Relaunch Sushi to load them.\n'
