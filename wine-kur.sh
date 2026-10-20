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
sudo apt-get update
sudo apt-get install -y --install-recommends winehq-stable
sudo apt-get install -y unzip
sudo apt-get install -y p7zip-full 2>/dev/null || sudo apt-get install -y 7zip
echo
wine --version && echo "Tamam. Şimdi: ./setup.sh"
