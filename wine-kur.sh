#!/bin/bash
# Installs Wine + 7z + unzip on Debian/Ubuntu based distributions (needs internet and sudo).
# Wine + 7z + unzip kurar (Debian/Ubuntu tabanlı dağıtımlar; internet ve sudo gerekir).
#  - Default: WineHQ stable (winehq-stable) from the official WineHQ repository. This is the tested setup.
#  - On Debian-family systems (Debian, Devuan, Pardus ...) the distribution's own Wine package (wine64)
#    is used as a fallback if WineHQ does not work.
# Force the source / Kaynağı zorlamak için:  WINE_SOURCE=winehq ./wine-kur.sh   or   WINE_SOURCE=distro ./wine-kur.sh
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/lib.sh"
export LC_ALL=C   # parse apt output independent of the language / apt çıktısı dilden bağımsız ayrıştırılsın
[ "$(uname -m)" = x86_64 ] || err "Only 64-bit (x86_64) systems are supported." "Sadece 64-bit (x86_64) sistemler destekleniyor."
command -v apt-get >/dev/null || err "This script is only for Debian/Ubuntu based systems. For others see: https://gitlab.winehq.org/wine/wine/-/wikis/Download" "Bu script sadece Debian/Ubuntu tabanlı sistemler içindir. Diğerleri için: https://gitlab.winehq.org/wine/wine/-/wikis/Download"
. /etc/os-release

# --- distribution family and WineHQ codename / dağıtım ailesi ve WineHQ kod adı ---
if [ "$ID" = ubuntu ] || [[ " $ID_LIKE " == *" ubuntu "* ]] || [ -n "$UBUNTU_CODENAME" ]; then
  BASE=ubuntu; CODE="${UBUNTU_CODENAME:-$VERSION_CODENAME}"
elif [ "$ID" = debian ] || [[ " $ID_LIKE " == *" debian "* ]]; then
  BASE=debian
  DV=$(cat /etc/debian_version 2>/dev/null)
  case "${DV%%.*}" in
    11) CODE=bullseye ;; 12) CODE=bookworm ;; 13) CODE=trixie ;; 14) CODE=forky ;;
    *) case "${DV%%/*}" in   # Devuan: e.g. "daedalus/ceres"; map to the Debian equivalent
         chimaera) CODE=bullseye ;; daedalus) CODE=bookworm ;; excalibur) CODE=trixie ;;
         *) CODE="${DV%%/*}" ;;
       esac ;;
  esac
else
  err "Distribution not recognized ($PRETTY_NAME)." "Dağıtım tanınmadı ($PRETTY_NAME)."
fi
[ -n "$CODE" ] || err "Could not determine the distribution release name." "Dağıtım sürüm adı bulunamadı."
say "System: $PRETTY_NAME (family: $BASE, codename: $CODE)" "Sistem: $PRETTY_NAME (aile: $BASE, kod adı: $CODE)"

SOURCE="${WINE_SOURCE:-${WINE_KAYNAK:-winehq}}"   # WINE_KAYNAK=dagitim|winehq (old name) still works
[ "$SOURCE" = dagitim ] && SOURCE=distro

say "This will ask for your sudo password." "Bu işlem sudo şifrenizi isteyecek."
sudo apt-get update || say "Warning: apt-get update reported errors (maybe another repository), continuing." "Uyarı: apt-get update hata verdi (başka bir depo olabilir), devam ediliyor."

# major number of the candidate version of a package (empty if none)
cand_major() { apt-cache policy "$1" 2>/dev/null | awk '/Candidate:/{print $2}' | grep -oE '^[0-9]+' | head -1; }

install_winehq() {
  local SRC="https://dl.winehq.org/wine-builds/$BASE/dists/$CODE/winehq-$CODE.sources" GET
  if command -v wget >/dev/null; then GET="wget -qO-"
  elif command -v curl >/dev/null; then GET="curl -fsSL"
  else sudo apt-get install -y wget; GET="wget -qO-"
  fi
  $GET "$SRC" >/dev/null 2>&1 || { say "WineHQ offers no packages for this release: $SRC" "WineHQ bu sürüm için paket sunmuyor: $SRC"; return 1; }
  say "Adding the WineHQ repository: $BASE/$CODE" "WineHQ deposu ekleniyor: $BASE/$CODE"
  sudo dpkg --add-architecture i386
  sudo mkdir -pm755 /etc/apt/keyrings
  $GET https://dl.winehq.org/wine-builds/winehq.key | sudo gpg --dearmor --yes -o /etc/apt/keyrings/winehq-archive.key
  $GET "$SRC" | sudo tee /etc/apt/sources.list.d/winehq-$CODE.sources >/dev/null
  sudo apt-get update || say "Warning: apt-get update reported errors, continuing." "Uyarı: apt-get update hata verdi, devam ediliyor."
  apt-cache policy winehq-stable | grep -q 'Candidate: [^(]' || { say "Package winehq-stable not found (apt update may have failed)." "winehq-stable paketi bulunamadı (apt update başarısız olmuş olabilir)."; return 1; }
  say "Installing Wine: sudo apt install --install-recommends winehq-stable" "Wine kuruluyor: sudo apt install --install-recommends winehq-stable"
  sudo apt-get install -y --install-recommends winehq-stable || return 1
}

install_distro() {
  local major; major=$(cand_major wine64)
  [ -n "$major" ] || { say "No 'wine64' package in the distribution repositories." "Dağıtım deposunda 'wine64' paketi yok."; return 1; }
  [ "$major" -ge 9 ] || { say "The distribution's Wine ($major) is too old (need at least 9)." "Dağıtımın Wine sürümü ($major) çok eski (en az 9 gerekir)."; return 1; }
  say "Installing the distribution's Wine $major: sudo apt install wine wine64 libwine fonts-wine (untested with SmartPSS Lite)" "Dağıtımın Wine $major paketi kuruluyor: sudo apt install wine wine64 libwine fonts-wine (SmartPSS Lite ile denenmedi)"
  sudo apt-get install -y wine wine64 libwine fonts-wine || return 1
}

if [ "$SOURCE" = distro ]; then
  install_distro || { say "Distribution package failed, trying WineHQ..." "Dağıtım paketi kurulamadı, WineHQ deneniyor..."; install_winehq; } \
    || err "Wine could not be installed. See the messages above." "Wine kurulamadı. Yukarıdaki mesajlara bakın."
else
  install_winehq || { [ "$BASE" = debian ] && { say "WineHQ failed, trying the distribution's Wine package..." "WineHQ olmadı, dağıtımın Wine paketi deneniyor..."; install_distro; }; } \
    || err "Wine could not be installed. See the messages above." "Wine kurulamadı. Yukarıdaki mesajlara bakın."
fi

sudo apt-get install -y unzip || true
sudo apt-get install -y p7zip-full 2>/dev/null || sudo apt-get install -y 7zip || true
echo
command -v wine >/dev/null || err "Installation finished but the 'wine' command was not found. Close and reopen the terminal." "Kurulum bitti ama 'wine' komutu bulunamadı. Terminali kapatıp açın."
wine --version && say "Done. Now run: ./setup.sh" "Tamam. Şimdi: ./setup.sh"
