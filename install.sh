#!/usr/bin/env bash
set -euo pipefail

UUID="gnome-app-status@roverflow"
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
EXTENSION_DIR="${HOME}/.local/share/gnome-shell/extensions/${UUID}"

info()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m::\033[0m %s\n' "$*"; }
error() { printf '\033[1;31m::\033[0m %s\n' "$*" >&2; }
die()   { error "$*"; exit 1; }

for cmd in glib-compile-schemas gnome-shell; do
    command -v "$cmd" >/dev/null 2>&1 || die "'$cmd' not found — is GNOME Shell installed?"
done

[[ -f "${SRC_DIR}/metadata.json" ]] || die "metadata.json not found in ${SRC_DIR}"

if [[ -d "$EXTENSION_DIR" ]]; then
    info "Removing previous installation"
    rm -rf "$EXTENSION_DIR"
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

info "Staging files"

cp "$SRC_DIR"/*.js        "$TMP_DIR/"
cp "$SRC_DIR/metadata.json" "$TMP_DIR/"
cp "$SRC_DIR/stylesheet.css" "$TMP_DIR/"

cp -r "$SRC_DIR/interfaces-xml" "$TMP_DIR/"
cp -r "$SRC_DIR/preferences"    "$TMP_DIR/"

mkdir -p "$TMP_DIR/icons/hicolor/scalable"
cp -r "$SRC_DIR/icons/hicolor/scalable/actions" "$TMP_DIR/icons/hicolor/scalable/"

mkdir -p "$TMP_DIR/schemas"
cp "$SRC_DIR"/schemas/*.gschema.xml "$TMP_DIR/schemas/"
glib-compile-schemas "$TMP_DIR/schemas/" || die "Schema compilation failed"

info "Installing to ${EXTENSION_DIR}"
mkdir -p "$(dirname "$EXTENSION_DIR")"
mv "$TMP_DIR" "$EXTENSION_DIR"
trap - EXIT

info "Done — restart GNOME Shell to activate"
info "  Wayland: log out and back in"
info "  X11:     Alt+F2 → r"
