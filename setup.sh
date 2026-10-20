#!/bin/bash
# SmartPSS Lite Linux (Wine) kurulumu
# Dahua'nın SmartPSS Lite zip dosyasını bu klasörün içinde arar (veya SMARTPSS_ZIP=/yol/dosya.zip ile verin).
# vc_redist.x64.exe yoksa Microsoft'tan indirir.
# Gereken: 64-bit Wine (WineHQ 11 önerilir), 7z, unzip. Yoksa önce: ./wine-kur.sh
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
export WINEPREFIX="${WINEPREFIX:-$DIR/prefix}" WINEARCH=win64 WINEDEBUG=-all
# Wine Mono/Gecko gerekmez (kurulum penceresi açılmasın); winemenubuilder dosya ilişkilendirmelerini bozmasın
export WINEDLLOVERRIDES="mscoree,mshtml=;winemenubuilder.exe=d"
APP="$WINEPREFIX/drive_c/Program Files/SmartPSSLite"
err() { echo "HATA: $*" >&2; exit 1; }

echo "[0/6] Gereksinimler kontrol ediliyor"
[ "$(uname -m)" = x86_64 ] || err "Sadece 64-bit (x86_64) bilgisayarlar destekleniyor."
command -v wine >/dev/null || err "Wine kurulu değil. Önce ./wine-kur.sh çalıştırın (bkz. KURULUM.txt)."
V=$(wine --version 2>/dev/null | grep -oE '[0-9]+(\.[0-9]+)?' | head -1); MAJ=${V%%.*}
[ "${MAJ:-0}" -ge 9 ] || err "Wine sürümü çok eski (${V:-bilinmiyor}). En az 9, önerilen 11. ./wine-kur.sh ile güncelleyin."
[ "$MAJ" -ge 11 ] || echo "  Uyarı: Wine $V bulundu, test edilen sürüm 11. Sorun olursa ./wine-kur.sh ile güncelleyin."
command -v unzip >/dev/null || err "unzip kurulu değil (sudo apt install unzip)."
SZ=$(command -v 7z || command -v 7za || command -v 7zz) || err "7z kurulu değil (sudo apt install p7zip-full veya 7zip)."
if [ -n "$SMARTPSS_ZIP" ]; then ZIP="$SMARTPSS_ZIP"; else
  shopt -s nullglob; Z=("$DIR"/General_SmartPSSLite_*.zip); shopt -u nullglob
  ZIP="${Z[0]}"
fi
[ -f "$ZIP" ] || err "SmartPSS Lite zip dosyası bulunamadı. dahuasecurity.com'dan indirip bu klasöre koyun (Dahua Wiki'deki sürüm eskidir, kullanmayın)
  (dosya adı: General_SmartPSSLite_MultiLang_Win64-Install_IS_V1.006.0000000.1.R.260305.zip) veya
  SMARTPSS_ZIP=/yol/dosya.zip ./setup.sh şeklinde çalıştırın. Ayrıntı: README.md"
if [ ! -f "$DIR/vc_redist.x64.exe" ]; then
  echo "vc_redist.x64.exe bulunamadı, Microsoft'tan indiriliyor (~25 MB)"
  URL=https://aka.ms/vs/17/release/vc_redist.x64.exe
  { command -v curl >/dev/null && curl -fsSL -o "$DIR/vc_redist.x64.exe" "$URL"; } || \
  { command -v wget >/dev/null && wget -qO "$DIR/vc_redist.x64.exe" "$URL"; } || \
    { rm -f "$DIR/vc_redist.x64.exe"; err "vc_redist.x64.exe indirilemedi. $URL adresinden indirip bu klasöre koyun."; }
fi
FREE=$(df -Pk "$DIR" | awk 'NR==2{print int($4/1024/1024)}')
[ "$FREE" -ge 3 ] || err "Yetersiz disk alanı: ${FREE} GB boş, en az 3 GB gerekli."
if [ -f "$APP/SmartPSSLite.exe" ]; then
  echo "Zaten kurulu: $APP"
  echo "Başlatmak için: $DIR/run.sh   (Sıfırdan kurmak için önce ./uninstall.sh)"
  exit 0
fi

echo "[1/6] Wine ortamı oluşturuluyor: $WINEPREFIX"
wineboot -i >/dev/null 2>&1 || true; wineserver -w
grep -q '^#arch=win64' "$WINEPREFIX/system.reg" 2>/dev/null || \
  err "64-bit Wine ortamı oluşturulamadı. Wine'ın 64-bit desteği eksik olabilir (WineHQ önerilir: ./wine-kur.sh)."

echo "[2/6] Uygulama çıkarılıyor (birkaç dakika sürebilir)"
TMP="$DIR/.setup-tmp"; rm -rf "$TMP"; mkdir -p "$TMP"; trap 'rm -rf "$TMP"' EXIT
unzip -q -o "$ZIP" -d "$TMP"
"$SZ" x -y -o"$TMP/app" "$TMP"/*.exe >/dev/null
rm -rf "$TMP/app/\$PLUGINSDIR"
[ -f "$TMP/app/SmartPSSLite.exe" ] || err "Kurulum dosyası açılamadı (SmartPSSLite.exe çıkmadı)."
mkdir -p "$APP"; cp -r "$TMP/app/." "$APP/"

echo "[3/6] Microsoft VC++ runtime kuruluyor"
wine "$DIR/vc_redist.x64.exe" /install /quiet /norestart >/dev/null 2>&1 || true
wineserver -w
for d in msvcp140 msvcp140_1 msvcp140_2 msvcp140_atomic_wait msvcp140_codecvt_ids vcruntime140 vcruntime140_1 concrt140; do
  wine reg add 'HKCU\Software\Wine\DllOverrides' /v $d /t REG_SZ /d native,builtin /f >/dev/null 2>&1
done
strings -el "$WINEPREFIX/drive_c/windows/system32/msvcp140.dll" 2>/dev/null | grep -q '^14\.' || \
  [ "$(stat -c %s "$WINEPREFIX/drive_c/windows/system32/msvcp140.dll" 2>/dev/null || echo 0)" -gt 300000 ] || \
  echo "  Uyarı: VC++ runtime kurulmamış görünüyor; uygulama çökebilir."

echo "[4/6] Wine ayarları"
# Heap debug bayrakları (Wine'ın LFH heap'ini kapatır). Bu olmadan login sonrası
# siyah ekran + sürekli çökme/yeniden başlama döngüsü oluyor. SİLMEYİN.
wine reg add 'HKLM\System\CurrentControlSet\Control\Session Manager' /v GlobalFlag /t REG_DWORD /d 0x4070 /f >/dev/null 2>&1
wineserver -w

echo "[5/6] Kullanıcı dizinleri hazırlanıyor"
U="$WINEPREFIX/drive_c/users/Public/SmartPSSLite"
mkdir -p "$U"/Conf/User/OrganizationBackup "$U"/Data/User/Database/{Log,LocalRes} \
  "$U"/Data/User/Picture/{Capture,AccessCapture,FacePictures,HumanTraitPictures,FaceGather,IvsPic} \
  "$U"/Data/User/Record "$U"/Log/{client_log,sdk_log}
wineserver -k 2>/dev/null || true

echo "[6/6] Menü ve masaüstü kısayolu oluşturuluyor"
APPS="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
mkdir -p "$APPS"
cat > "$APPS/smartpss-lite.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=SmartPSS Lite
Comment=Dahua SmartPSS Lite (Wine)
Exec="$DIR/run.sh"
Icon=camera-video
Terminal=false
Categories=AudioVideo;Video;Network;
StartupWMClass=smartpsslite.exe
EOF
chmod +x "$APPS/smartpss-lite.desktop"
DESK="${XDG_DESKTOP_DIR:-$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")}"
if [ -d "$DESK" ] && [ "$DESK" != "$HOME" ]; then
  cp "$APPS/smartpss-lite.desktop" "$DESK/"
  chmod +x "$DESK/smartpss-lite.desktop"
  gio set "$DESK/smartpss-lite.desktop" metadata::trusted true 2>/dev/null || true
fi
command -v update-desktop-database >/dev/null && update-desktop-database "$APPS" 2>/dev/null || true

echo
echo "Kurulum tamamlandı."
echo "Başlatmak için: uygulama menüsünde/masaüstünde 'SmartPSS Lite' veya $DIR/run.sh"
echo "İlk açılışta yönetici (admin) hesabı oluşturmanız istenecek."
