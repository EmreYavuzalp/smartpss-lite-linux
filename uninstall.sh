#!/bin/bash
# SmartPSS Lite'ı kaldırır: Wine ortamını (prefix) ve kısayolları siler.
# Paket dosyalarına (zip, vc_redist, scriptler) dokunmaz; tekrar kurmak için ./setup.sh
DIR="$(cd "$(dirname "$0")" && pwd)"
export WINEPREFIX="${WINEPREFIX:-$DIR/prefix}"
echo "Silinecek: $WINEPREFIX"
echo "UYARI: Hesaplar, eklenen cihazlar, kayıtlar ve ekran görüntüleri de silinir."
read -r -p "Devam edilsin mi? [e/H] " a; [[ "$a" =~ ^[eEyY]$ ]] || { echo "İptal."; exit 0; }
wineserver -k 2>/dev/null || true
rm -rf "$WINEPREFIX"
APPS="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
DESK="${XDG_DESKTOP_DIR:-$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")}"
rm -f "$APPS/smartpss-lite.desktop" "$DESK/smartpss-lite.desktop"
echo "Kaldırıldı."
