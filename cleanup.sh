#!/bin/bash
# Frees disk space after installation. Asks before every step. Does NOT touch account/device data (users/Public/SmartPSSLite/{Conf,Data}).
# Kurulumdan sonra yer açar. Her adım onay ister. Hesap/cihaz verisine DOKUNMAZ.
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/lib.sh"
export WINEPREFIX="${WINEPREFIX:-$DIR/prefix}"
C="$WINEPREFIX/drive_c"
[ -d "$C" ] || err "No prefix at $WINEPREFIX" "Prefix yok: $WINEPREFIX"

say "== Stopping the application first ==" "== Önce uygulama kapatılıyor =="; wineserver -k 2>/dev/null
mapfile -d '' D < <(find "$C" -name '*.dmp' -print0 2>/dev/null)
[ ${#D[@]} -gt 0 ] && { say "Crash dumps:" "Çökme dökümleri:"; du -ch "${D[@]}" | tail -1; ask "Delete them?" "Silinsin mi?" && rm -f "${D[@]}"; }
T=(); for t in "$C"/users/*/AppData/Local/Temp "$C"/windows/temp; do [ -d "$t" ] && T+=("$t"); done
[ ${#T[@]} -gt 0 ] && { du -ch "${T[@]}" | tail -1; ask "Delete temporary files?" "Geçici dosyalar silinsin mi?" && for t in "${T[@]}"; do find "$t" -mindepth 1 -delete; done; }
L="$C/users/Public/SmartPSSLite/Log"
[ -d "$L" ] && { du -sh "$L"; ask "Delete application logs?" "Uygulama log'ları silinsin mi?" && find "$L" -type f -delete; }
M="$C/windows/mono"
[ -d "$M" ] && { du -sh "$M"; say "(Wine Mono: SmartPSS is a native Qt app and does not use .NET)" "(Wine Mono: SmartPSS native Qt uygulaması, .NET kullanmaz)"; ask "Delete Wine Mono?" "Wine Mono silinsin mi?" && rm -rf "$M"; }
K=(); for f in "$DIR"/General_SmartPSSLite_*.zip "$DIR"/vc_redist.x64.exe "$DIR"/*.tar "$DIR"/../*.tar; do [ -f "$f" ] && K+=("$f"); done
[ ${#K[@]} -gt 0 ] && { du -ch "${K[@]}" | tail -1; ask "Delete installer files (zip, vc_redist, tar)? They are needed for a reinstall." "Kurulum dosyaları (zip, vc_redist, tar) silinsin mi? Yeniden kurulum için gerekir."  && rm -f "${K[@]}"; }
say "Done." "Bitti."; du -sh "$WINEPREFIX" 2>/dev/null
