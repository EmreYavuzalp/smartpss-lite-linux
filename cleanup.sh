#!/bin/bash
# Kurulumdan sonra yer açar. Her adım onay ister. Hesap/cihaz verisine (users/Public/SmartPSSLite/{Conf,Data}) DOKUNMAZ.
DIR="$(cd "$(dirname "$0")" && pwd)"
export WINEPREFIX="${WINEPREFIX:-$DIR/prefix}"
C="$WINEPREFIX/drive_c"
[ -d "$C" ] || { echo "Prefix yok: $WINEPREFIX"; exit 1; }
ask() { read -r -p "$1 [e/H] " a; [[ "$a" =~ ^[eEyY]$ ]]; }

echo "== Önce uygulama kapatılıyor =="; wineserver -k 2>/dev/null
mapfile -d '' D < <(find "$C" -name '*.dmp' -print0 2>/dev/null)
[ ${#D[@]} -gt 0 ] && { echo "Çökme dökümleri:"; du -ch "${D[@]}" | tail -1; ask "Silinsin mi?" && rm -f "${D[@]}"; }
T=(); for t in "$C"/users/*/AppData/Local/Temp "$C"/windows/temp; do [ -d "$t" ] && T+=("$t"); done
[ ${#T[@]} -gt 0 ] && { du -ch "${T[@]}" | tail -1; ask "Geçici dosyalar silinsin mi?" && for t in "${T[@]}"; do find "$t" -mindepth 1 -delete; done; }
L="$C/users/Public/SmartPSSLite/Log"
[ -d "$L" ] && { du -sh "$L"; ask "Uygulama log'ları silinsin mi?" && find "$L" -type f -delete; }
M="$C/windows/mono"
[ -d "$M" ] && { du -sh "$M"; echo "(Wine Mono: SmartPSS native Qt uygulaması, .NET kullanmaz)"; ask "Wine Mono silinsin mi?" && rm -rf "$M"; }
K=(); for f in "$DIR"/General_SmartPSSLite_*.zip "$DIR"/vc_redist.x64.exe "$DIR"/*.tar "$DIR"/../*.tar; do [ -f "$f" ] && K+=("$f"); done
[ ${#K[@]} -gt 0 ] && { du -ch "${K[@]}" | tail -1; ask "Kurulum dosyaları (zip, vc_redist, tar) silinsin mi? (yeniden kurulum için gerekir)" && rm -f "${K[@]}"; }
echo "Bitti."; du -sh "$WINEPREFIX" 2>/dev/null
