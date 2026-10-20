#!/bin/bash
# WineHQ (kararlı sürüm) + 7z + unzip kurar. Debian/Ubuntu tabanlı dağıtımlar içindir
# (Debian, Ubuntu, Pardus, Linux Mint, Zorin, Pop!_OS ...). İnternet ve sudo yetkisi gerekir.
set -e
err() { echo "HATA: $*" >&2; exit 1; }
[ "$(uname -m)" = x86_64 ] || err "Sadece 64-bit (x86_64) sistemler destekleniyor."
command -v apt-get >/dev/null || err "Bu script sadece Debian/Ubuntu tabanlı sistemler içindir. Diğerleri için: https://gitlab.winehq.org/wine/wine/-/wikis/Download"
. /etc/os-release

if [ "$ID" = ubuntu ] || [[ " $ID_LIKE " == *" ubuntu "* ]] || [ -n "$UBUNTU_CODENAME" ]; then
  BASE=ubuntu; CODE="${UBUNTU_CODENAME:-$VERSION_CODENAME}"
elif [ "$ID" = debian ] || [[ " $ID_LIKE " == *" debian "* ]]; then
  BASE=debian; DV=$(cat /etc/debian_version 2>/dev/null)
  case "${DV%%.*}" in
    12) CODE=bookworm ;; 13) CODE=trixie ;; 14) CODE=forky ;;
    *) CODE="${DV%%/*}" ;;   # ör. "trixie/sid"
  esac
else
  err "Dağıtım tanınmadı ($PRETTY_NAME)."
fi
[ -n "$CODE" ] || err "Dağıtım sürüm adı bulunamadı."
SRC="https://dl.winehq.org/wine-builds/$BASE/dists/$CODE/winehq-$CODE.sources"
echo "Sistem: $PRETTY_NAME -> WineHQ deposu: $BASE/$CODE"

if command -v wget >/dev/null; then GET="wget -qO-"
elif command -v curl >/dev/null; then GET="curl -fsSL"
else sudo apt-get update; sudo apt-get install -y wget; GET="wget -qO-"
fi
$GET "$SRC" >/dev/null 2>&1 || err "WineHQ bu sürüm için paket sunmuyor: $SRC
Dağıtımın kendi Wine paketini deneyebilirsiniz: sudo apt install wine wine64 (test edilmedi)."

echo "Bu işlem sudo şifrenizi isteyecek."
sudo dpkg --add-architecture i386
sudo mkdir -pm755 /etc/apt/keyrings
$GET https://dl.winehq.org/wine-builds/winehq.key | sudo gpg --dearmor --yes -o /etc/apt/keyrings/winehq-archive.key
$GET "$SRC" | sudo tee /etc/apt/sources.list.d/winehq-$CODE.sources >/dev/null
echo "[1/3] Paket listesi güncelleniyor"
# Başka bir deponun hatası (ör. süresi dolmuş anahtar) kurulumu durdurmasın
sudo apt-get update || echo "Uyarı: apt-get update hata verdi (başka bir depo olabilir), devam ediliyor."

echo "[2/3] WineHQ paketi kontrol ediliyor"
apt-cache policy winehq-stable | sed 's/^/  /'
apt-cache policy winehq-stable | grep -q 'Candidate: [^(]' || \
  err "winehq-stable paketi bulunamadı. Depo eklenmiş olabilir ama 'apt-get update' başarısız olmuş olabilir.
Kontrol edin: cat /etc/apt/sources.list.d/winehq-$CODE.sources ; sudo apt-get update
Sonra elle: sudo apt install --install-recommends winehq-stable"

echo "[3/3] Wine kuruluyor (sudo apt install --install-recommends winehq-stable)"
if ! sudo apt-get install -y --install-recommends winehq-stable; then
  echo
  err "winehq-stable kurulamadı (yukarıdaki apt hatasına bakın). Elle deneyin:
  sudo apt update && sudo apt install --install-recommends winehq-stable
Bağımlılık sorunu varsa: sudo apt --fix-broken install"
fi
sudo apt-get install -y unzip || true
sudo apt-get install -y p7zip-full 2>/dev/null || sudo apt-get install -y 7zip || true
echo
command -v wine >/dev/null || err "Kurulum bitti ama 'wine' komutu bulunamadı. Terminali kapatıp açın veya: ls /opt/wine-stable/bin"
wine --version && echo "Tamam. Şimdi: ./setup.sh"
