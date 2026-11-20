# Dolphin Sushi

Dolphin Sushi builds KDE Dolphin 26.08.3 with one local-file shortcut. Select a file and press **Space** to open it in GNOME Sushi. Press **Space** or **Escape** in Sushi to close the preview. Dolphin's selection mode is still available from its menu.

The application installs under `~/.local/opt/dolphin-sushi`. It has its own desktop entry, executable, D-Bus identity, and settings file `~/.config/dolphinsushirc`.

## Build and install

The installer expects Git, CMake, a C++ compiler, the Qt 6 and KDE Frameworks development dependencies for [Dolphin 26.08.3](https://invent.kde.org/system/dolphin/-/tree/v26.08.3), and `sushi` on `PATH`. It was developed on Fedora 45 with Plasma 6.

```sh
./install.sh
```

Open **Dolphin Sushi** from the application menu or run `~/.local/bin/dolphin-sushi`. `JOBS=4 ./install.sh` limits parallel compilation. The installer fetches upstream Dolphin into the ignored `build/` directory and applies [the Dolphin patch](patches/dolphin-sushi.patch).

## Optional preview appearance

```sh
./scripts/install-preview-overrides.sh
```

This applies [the Sushi 51.2 resource patch](patches/sushi-51.2-preview.patch) to the installed GNOME Sushi resources. It hides the header and sizes PDF previews to the shape of the page. The resource override applies to Sushi for the current user. It expects the Fedora Sushi 51.2 resource layout, `gresource`, and GNU `patch`.

## Source and licenses

The file manager is [KDE Dolphin](https://invent.kde.org/system/dolphin) and the previewer is [GNOME Sushi](https://gitlab.gnome.org/GNOME/sushi). The patches retain the projects' licensing terms. See [GPL-2.0-or-later](LICENSE) and the [Sushi license and exception](licenses/Sushi-COPYING.txt).
