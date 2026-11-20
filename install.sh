#!/usr/bin/env bash
# Separate Dolphin 26.08.3 build with a Space-to-Sushi shortcut.
set -euo pipefail
repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_dir="$repo_dir/build/dolphin-sushi"
build_dir="$source_dir/build"
prefix="$HOME/.local/opt/dolphin-sushi"

if [[ "${1:-}" != --install-only ]]; then
    command -v sushi >/dev/null || { echo 'Install Sushi first.' >&2; exit 1; }
    if [[ ! -e "$source_dir/.git" ]]; then
        mkdir -p "$source_dir"
        git -C "$source_dir" init -q
        git -C "$source_dir" remote add origin https://invent.kde.org/system/dolphin.git
        git -C "$source_dir" fetch --depth 1 origin tag v26.08.3
        git -C "$source_dir" checkout -q --detach v26.08.3
    fi
    [[ "$(git -C "$source_dir" describe --tags --exact-match HEAD)" == v26.08.3 ]] || {
        echo 'Expected Dolphin v26.08.3 source.' >&2; exit 1;
    }
    patch_file="$repo_dir/patches/dolphin-sushi.patch"
    if git -C "$source_dir" apply --check "$patch_file" 2>/dev/null; then
        git -C "$source_dir" apply "$patch_file"
    else
        git -C "$source_dir" apply --reverse --check "$patch_file"
    fi
    cmake -S "$source_dir" -B "$build_dir" \
        -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF \
        -DCMAKE_INSTALL_PREFIX="$prefix" -DKDE_INSTALL_USE_QT_SYS_PATHS=OFF \
        -DKDE_INSTALL_LIBDIR=lib64 -DKDE_INSTALL_PLUGINDIR=lib64/plugins \
        -DCMAKE_INSTALL_RPATH="$prefix/lib64"
    cmake --build "$build_dir" -j"${JOBS:-6}"
fi

[[ ! -L "$prefix" ]] || { echo 'Refusing symlinked prefix.' >&2; exit 1; }
grep -Fx "CMAKE_INSTALL_PREFIX:PATH=$prefix" "$build_dir/CMakeCache.txt" >/dev/null
cmake --install "$build_dir"
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications" "$HOME/.config"
if [[ ! -e "$HOME/.config/dolphinsushirc" && -f "$HOME/.config/dolphinrc" ]]; then
    cp "$HOME/.config/dolphinrc" "$HOME/.config/dolphinsushirc"
fi
cat > "$HOME/.local/bin/dolphin-sushi" <<'EOF'
#!/usr/bin/env bash
prefix="$HOME/.local/opt/dolphin-sushi"
export QT_PLUGIN_PATH="$prefix/lib64/plugins${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
exec "$prefix/bin/dolphin-sushi" "$@"
EOF
chmod +x "$HOME/.local/bin/dolphin-sushi"
cat > "$HOME/.local/share/applications/org.kde.dolphinsushi.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Dolphin Sushi
GenericName=File Manager
Comment=Preview a selected file in Sushi with Space
Exec=dolphin-sushi %U
Icon=org.kde.dolphin
Terminal=false
Categories=Qt;KDE;System;FileTools;FileManager;
MimeType=inode/directory;
StartupNotify=true
StartupWMClass=org.kde.dolphinsushi
EOF
desktop-file-validate "$HOME/.local/share/applications/org.kde.dolphinsushi.desktop"
if command -v kbuildsycoca6 >/dev/null; then
    kbuildsycoca6 --noincremental
fi
echo 'Installed Dolphin Sushi. Launch dolphin-sushi from the terminal or menu.'
