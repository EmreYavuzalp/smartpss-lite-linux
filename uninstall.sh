#!/bin/bash
# Removes SmartPSS Lite: deletes the Wine prefix and the shortcuts. Package files (zip, scripts) stay; reinstall with ./setup.sh
# SmartPSS Lite'ı kaldırır: Wine ortamını (prefix) ve kısayolları siler. Tekrar kurmak için ./setup.sh
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/lib.sh"
export WINEPREFIX="${WINEPREFIX:-$DIR/prefix}"
say "To be deleted: $WINEPREFIX" "Silinecek: $WINEPREFIX"
say "WARNING: accounts, added devices, recordings and screenshots are deleted too." "UYARI: Hesaplar, eklenen cihazlar, kayıtlar ve ekran görüntüleri de silinir."
ask "Continue?" "Devam edilsin mi?" || { say "Cancelled." "İptal."; exit 0; }
wineserver -k 2>/dev/null || true
rm -rf "$WINEPREFIX"
APPS="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
DESK="${XDG_DESKTOP_DIR:-$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")}"
rm -f "$APPS/smartpss-lite.desktop" "$DESK/smartpss-lite.desktop"
say "Removed." "Kaldırıldı."
