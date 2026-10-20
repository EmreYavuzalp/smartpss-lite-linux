#!/bin/bash
# SmartPSS Lite on Linux (Wine) - installer / kurulum
# Looks for Dahua's SmartPSS Lite zip in this folder (or pass SMARTPSS_ZIP=/path/file.zip).
# Downloads vc_redist.x64.exe from Microsoft if it is missing.
# Needs: 64-bit Wine (WineHQ 11 recommended), 7z, unzip. If missing run ./wine-install.sh first.
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/lib.sh"
export WINEPREFIX="${WINEPREFIX:-$DIR/prefix}" WINEARCH=win64 WINEDEBUG=-all
# Wine Mono/Gecko not needed (no install dialog); winemenubuilder must not touch file associations
export WINEDLLOVERRIDES="mscoree,mshtml=;winemenubuilder.exe=d"
APP="$WINEPREFIX/drive_c/Program Files/SmartPSSLite"

say "[0/6] Checking requirements" "[0/6] Gereksinimler kontrol ediliyor"
[ "$(uname -m)" = x86_64 ] || err "Only 64-bit (x86_64) computers are supported." "Sadece 64-bit (x86_64) bilgisayarlar destekleniyor."
command -v wine >/dev/null || err "Wine is not installed. Run ./wine-install.sh first (see README.md)." "Wine kurulu değil. Önce ./wine-install.sh çalıştırın (bkz. README.tr.md)."
V=$(wine --version 2>/dev/null | grep -oE '[0-9]+(\.[0-9]+)?' | head -1); MAJ=${V%%.*}
[ "${MAJ:-0}" -ge 9 ] || err "Wine is too old (${V:-unknown}). Need at least 9, 11 recommended. Update with ./wine-install.sh." "Wine sürümü çok eski (${V:-bilinmiyor}). En az 9, önerilen 11. ./wine-install.sh ile güncelleyin."
[ "$MAJ" -ge 11 ] || say "  Warning: found Wine $V, the tested version is 11. If you hit problems update with ./wine-install.sh." "  Uyarı: Wine $V bulundu, test edilen sürüm 11. Sorun olursa ./wine-install.sh ile güncelleyin."
command -v unzip >/dev/null || err "unzip is not installed (sudo apt install unzip)." "unzip kurulu değil (sudo apt install unzip)."
SZ=$(command -v 7z || command -v 7za || command -v 7zz) || err "7z is not installed (sudo apt install p7zip-full or 7zip)." "7z kurulu değil (sudo apt install p7zip-full veya 7zip)."
if [ -n "$SMARTPSS_ZIP" ]; then ZIP="$SMARTPSS_ZIP"; else
  shopt -s nullglob; Z=("$DIR"/General_SmartPSSLite_*.zip); shopt -u nullglob
  ZIP="${Z[0]}"
fi
[ -f "$ZIP" ] || err "SmartPSS Lite zip not found. Download it from dahuasecurity.com and put it in this folder (do NOT use the outdated Dahua Wiki build).
  File name: General_SmartPSSLite_MultiLang_Win64-Install_IS_V1.006.0000000.1.R.260305.zip
  Or run: SMARTPSS_ZIP=/path/file.zip ./setup.sh   (details: README.md)" "SmartPSS Lite zip dosyası bulunamadı. dahuasecurity.com'dan indirip bu klasöre koyun (Dahua Wiki'deki eski sürümü KULLANMAYIN).
  Dosya adı: General_SmartPSSLite_MultiLang_Win64-Install_IS_V1.006.0000000.1.R.260305.zip
  Ya da: SMARTPSS_ZIP=/yol/dosya.zip ./setup.sh   (ayrıntı: README.tr.md)"
if [ ! -f "$DIR/vc_redist.x64.exe" ]; then
  say "vc_redist.x64.exe not found, downloading from Microsoft (~25 MB)" "vc_redist.x64.exe bulunamadı, Microsoft'tan indiriliyor (~25 MB)"
  URL=https://aka.ms/vs/17/release/vc_redist.x64.exe
  { command -v curl >/dev/null && curl -fsSL -o "$DIR/vc_redist.x64.exe" "$URL"; } || \
  { command -v wget >/dev/null && wget -qO "$DIR/vc_redist.x64.exe" "$URL"; } || \
    { rm -f "$DIR/vc_redist.x64.exe"; err "Could not download vc_redist.x64.exe. Download it from $URL and put it in this folder." "vc_redist.x64.exe indirilemedi. $URL adresinden indirip bu klasöre koyun."; }
fi
FREE=$(df -Pk "$DIR" | awk 'NR==2{print int($4/1024/1024)}')
[ "$FREE" -ge 3 ] || err "Not enough disk space: ${FREE} GB free, at least 3 GB needed." "Yetersiz disk alanı: ${FREE} GB boş, en az 3 GB gerekli."
if [ -f "$APP/SmartPSSLite.exe" ]; then
  say "Already installed: $APP" "Zaten kurulu: $APP"
  say "To start: $DIR/run.sh   (to reinstall from scratch run ./uninstall.sh first)" "Başlatmak için: $DIR/run.sh   (Sıfırdan kurmak için önce ./uninstall.sh)"
  exit 0
fi

say "[1/6] Creating the Wine environment: $WINEPREFIX" "[1/6] Wine ortamı oluşturuluyor: $WINEPREFIX"
wineboot -i >/dev/null 2>&1 || true; wineserver -w
grep -q '^#arch=win64' "$WINEPREFIX/system.reg" 2>/dev/null || \
  err "Could not create a 64-bit Wine environment. Wine may lack 64-bit support (WineHQ recommended: ./wine-install.sh)." "64-bit Wine ortamı oluşturulamadı. Wine'ın 64-bit desteği eksik olabilir (WineHQ önerilir: ./wine-install.sh)."

say "[2/6] Extracting the application (may take a few minutes)" "[2/6] Uygulama çıkarılıyor (birkaç dakika sürebilir)"
TMP="$DIR/.setup-tmp"; rm -rf "$TMP"; mkdir -p "$TMP"; trap 'rm -rf "$TMP"' EXIT
unzip -q -o "$ZIP" -d "$TMP"
"$SZ" x -y -o"$TMP/app" "$TMP"/*.exe >/dev/null
rm -rf "$TMP/app/\$PLUGINSDIR"
[ -f "$TMP/app/SmartPSSLite.exe" ] || err "Could not unpack the installer (SmartPSSLite.exe missing)." "Kurulum dosyası açılamadı (SmartPSSLite.exe çıkmadı)."
mkdir -p "$APP"; cp -r "$TMP/app/." "$APP/"

say "[3/6] Installing the Microsoft VC++ runtime" "[3/6] Microsoft VC++ runtime kuruluyor"
wine "$DIR/vc_redist.x64.exe" /install /quiet /norestart >/dev/null 2>&1 || true
wineserver -w
for d in msvcp140 msvcp140_1 msvcp140_2 msvcp140_atomic_wait msvcp140_codecvt_ids vcruntime140 vcruntime140_1 concrt140; do
  wine reg add 'HKCU\Software\Wine\DllOverrides' /v $d /t REG_SZ /d native,builtin /f >/dev/null 2>&1
done
strings -el "$WINEPREFIX/drive_c/windows/system32/msvcp140.dll" 2>/dev/null | grep -q '^14\.' || \
  [ "$(stat -c %s "$WINEPREFIX/drive_c/windows/system32/msvcp140.dll" 2>/dev/null || echo 0)" -gt 300000 ] || \
  say "  Warning: the VC++ runtime does not seem to be installed; the app may crash." "  Uyarı: VC++ runtime kurulmamış görünüyor; uygulama çökebilir."

say "[4/6] Wine settings" "[4/6] Wine ayarları"
# Heap debug flags (they disable Wine's LFH heap). Without this the app shows a black screen after
# login and crashes/restarts in a loop. DO NOT REMOVE. / Bu olmadan login sonrası siyah ekran + çökme döngüsü olur. SİLMEYİN.
wine reg add 'HKLM\System\CurrentControlSet\Control\Session Manager' /v GlobalFlag /t REG_DWORD /d 0x4070 /f >/dev/null 2>&1
wineserver -w

say "[5/6] Preparing user directories" "[5/6] Kullanıcı dizinleri hazırlanıyor"
U="$WINEPREFIX/drive_c/users/Public/SmartPSSLite"
mkdir -p "$U"/Conf/User/OrganizationBackup "$U"/Data/User/Database/{Log,LocalRes} \
  "$U"/Data/User/Picture/{Capture,AccessCapture,FacePictures,HumanTraitPictures,FaceGather,IvsPic} \
  "$U"/Data/User/Record "$U"/Log/{client_log,sdk_log}
wineserver -k 2>/dev/null || true

say "[6/6] Creating menu and desktop shortcuts" "[6/6] Menü ve masaüstü kısayolu oluşturuluyor"
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
say "Installation complete." "Kurulum tamamlandı."
say "To start: use 'SmartPSS Lite' in the app menu/desktop, or $DIR/run.sh" "Başlatmak için: uygulama menüsünde/masaüstünde 'SmartPSS Lite' veya $DIR/run.sh"
say "On first start you will be asked to create an administrator (admin) account." "İlk açılışta yönetici (admin) hesabı oluşturmanız istenecek."
