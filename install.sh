#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
UUID=$(sed -n 's/.*"uuid"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$SRC_DIR/metadata.json")
EXTENSION_DIR="${HOME}/.local/share/gnome-shell/extensions/${UUID}"

info()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }
error() { printf '\033[1;31m::\033[0m %s\n' "$*" >&2; }
die()   { error "$*"; exit 1; }

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTION]

Install, update, or remove the ${UUID} GNOME Shell extension.

Options:
  --uninstall   Remove the extension
  --help        Show this message
  (no flags)    Install or update the extension
EOF
}

do_install() {
    command -v glib-compile-schemas >/dev/null 2>&1 \
        || die "'glib-compile-schemas' not found — install glib2 development tools"

    [[ -f "${SRC_DIR}/metadata.json" ]] || die "metadata.json not found in ${SRC_DIR}"

    local tmp
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT

    info "Staging files"

    cp "$SRC_DIR"/*.js          "$tmp/"
    cp "$SRC_DIR/metadata.json" "$tmp/"
    cp "$SRC_DIR/stylesheet.css" "$tmp/"

    cp -r "$SRC_DIR/interfaces-xml" "$tmp/"
    cp -r "$SRC_DIR/preferences"    "$tmp/"

    mkdir -p "$tmp/icons/hicolor/scalable"
    cp -r "$SRC_DIR/icons/hicolor/scalable/actions" "$tmp/icons/hicolor/scalable/"

    mkdir -p "$tmp/schemas"
    cp "$SRC_DIR"/schemas/*.gschema.xml "$tmp/schemas/"
    glib-compile-schemas "$tmp/schemas/" || die "Schema compilation failed"

    [[ -d "$EXTENSION_DIR" ]] && rm -rf "$EXTENSION_DIR"

    mkdir -p "$(dirname "$EXTENSION_DIR")"
    mv "$tmp" "$EXTENSION_DIR"
    trap - EXIT

    info "Installed ${UUID} to ${EXTENSION_DIR}"
    info "Restart GNOME Shell to activate:"
    info "  Wayland — log out and back in"
    info "  X11    — Alt+F2 → r"
}

do_uninstall() {
    [[ -d "$EXTENSION_DIR" ]] || die "${UUID} is not installed"

    rm -rf "$EXTENSION_DIR"

    info "Removed ${UUID}"
    info "Restart GNOME Shell to complete removal"
}

case "${1:-}" in
    --uninstall) do_uninstall ;;
    --help|-h)   usage ;;
    "")          do_install ;;
    *)           error "Unknown option: $1"; usage; exit 1 ;;
esac
