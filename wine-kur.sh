#!/bin/bash
# Wine + 7z + unzip kurar. Debian/Ubuntu tabanlı dağıtımlar içindir (internet ve sudo gerekir).
#  - Debian, Devuan, Pardus ve diğer Debian tabanlılar: önce dağıtımın KENDİ Wine paketi (wine64) kurulur.
#    Sürümü 9'dan eskiyse WineHQ deposundan winehq-stable kurulur.
#  - Ubuntu, Linux Mint, Zorin, Pop!_OS ...: WineHQ deposundan winehq-stable kurulur.
# Kaynağı zorlamak için:  WINE_KAYNAK=dagitim ./wine-kur.sh    veya    WINE_KAYNAK=winehq ./wine-kur.sh
set -e
export LC_ALL=C   # apt çıktısı dilden bağımsız ayrıştırılsın
err() { echo "HATA: $*" >&2; exit 1; }
[ "$(uname -m)" = x86_64 ] || err "Sadece 64-bit (x86_64) sistemler destekleniyor."
command -v apt-get >/dev/null || err "Bu script sadece Debian/Ubuntu tabanlı sistemler içindir. Diğerleri için: https://gitlab.winehq.org/wine/wine/-/wikis/Download"
. /etc/os-release

# --- Dağıtım ailesi ve WineHQ kod adı ---
if [ "$ID" = ubuntu ] || [[ " $ID_LIKE " == *" ubuntu "* ]] || [ -n "$UBUNTU_CODENAME" ]; then
  BASE=ubuntu; CODE="${UBUNTU_CODENAME:-$VERSION_CODENAME}"
elif [ "$ID" = debian ] || [[ " $ID_LIKE " == *" debian "* ]]; then
  BASE=debian
  DV=$(cat /etc/debian_version 2>/dev/null)
  case "${DV%%.*}" in
    11) CODE=bullseye ;; 12) CODE=bookworm ;; 13) CODE=trixie ;; 14) CODE=forky ;;
    *) case "${DV%%/*}" in   # Devuan: "daedalus/ceres" gibi; sürüm adından Debian karşılığı
         chimaera) CODE=bullseye ;; daedalus) CODE=bookworm ;; excalibur) CODE=trixie ;;
         *) CODE="${DV%%/*}" ;;
       esac ;;
  esac
else
  err "Dağıtım tanınmadı ($PRETTY_NAME)."
fi
[ -n "$CODE" ] || err "Dağıtım sürüm adı bulunamadı."
echo "Sistem: $PRETTY_NAME (aile: $BASE, kod adı: $CODE)"

KAYNAK="${WINE_KAYNAK:-}"
[ -n "$KAYNAK" ] || { [ "$BASE" = debian ] && KAYNAK=dagitim || KAYNAK=winehq; }

echo "Bu işlem sudo şifrenizi isteyecek."
sudo apt-get update || echo "Uyarı: apt-get update hata verdi (başka bir depo olabilir), devam ediliyor."

wine_ok() { command -v wine >/dev/null; }
# apt-cache'ten aday sürümün ana numarası (yoksa boş)
aday_ana() { apt-cache policy "$1" 2>/dev/null | awk '/Candidate:/{print $2}' | grep -oE '^[0-9]+' | head -1; }

kur_dagitim() {
  local ana; ana=$(aday_ana wine64)
  [ -n "$ana" ] || { echo "Dağıtım deposunda 'wine64' paketi yok."; return 1; }
  [ "$ana" -ge 9 ] || { echo "Dağıtımın Wine sürümü ($ana) çok eski (en az 9 gerekir)."; return 1; }
  echo "Dağıtımın kendi Wine paketi kuruluyor (wine $ana): sudo apt install wine wine64 libwine fonts-wine"
  sudo apt-get install -y wine wine64 libwine fonts-wine || return 1
}

kur_winehq() {
  local SRC="https://dl.winehq.org/wine-builds/$BASE/dists/$CODE/winehq-$CODE.sources" GET
  if command -v wget >/dev/null; then GET="wget -qO-"
  elif command -v curl >/dev/null; then GET="curl -fsSL"
  else sudo apt-get install -y wget; GET="wget -qO-"
  fi
  $GET "$SRC" >/dev/null 2>&1 || { echo "WineHQ bu sürüm için paket sunmuyor: $SRC"; return 1; }
  echo "WineHQ deposu ekleniyor: $BASE/$CODE"
  sudo dpkg --add-architecture i386
  sudo mkdir -pm755 /etc/apt/keyrings
  $GET https://dl.winehq.org/wine-builds/winehq.key | sudo gpg --dearmor --yes -o /etc/apt/keyrings/winehq-archive.key
  $GET "$SRC" | sudo tee /etc/apt/sources.list.d/winehq-$CODE.sources >/dev/null
  sudo apt-get update || echo "Uyarı: apt-get update hata verdi, devam ediliyor."
  LC_ALL=C apt-cache policy winehq-stable | grep -q 'Candidate: [^(]' || { echo "winehq-stable paketi bulunamadı (apt update başarısız olmuş olabilir)."; return 1; }
  echo "Wine kuruluyor: sudo apt install --install-recommends winehq-stable"
  sudo apt-get install -y --install-recommends winehq-stable || return 1
}

if [ "$KAYNAK" = dagitim ]; then
  kur_dagitim || { echo "Dağıtım paketi kurulamadı, WineHQ deposu deneniyor..."; kur_winehq || err "Wine kurulamadı. Yukarıdaki mesajlara bakın."; }
else
  kur_winehq || { [ "$BASE" = debian ] && echo "WineHQ olmadı, dağıtım paketi deneniyor..." && kur_dagitim; } || err "Wine kurulamadı. Yukarıdaki mesajlara bakın."
fi

sudo apt-get install -y unzip || true
sudo apt-get install -y p7zip-full 2>/dev/null || sudo apt-get install -y 7zip || true
echo
wine_ok || err "Kurulum bitti ama 'wine' komutu bulunamadı. Terminali kapatıp açın."
wine --version && echo "Tamam. Şimdi: ./setup.sh"
