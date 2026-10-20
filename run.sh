#!/bin/bash
# Starts SmartPSS Lite with Wine (private prefix, does not touch ~/.wine)
# SmartPSS Lite'ı Wine ile başlatır (özel prefix kullanır, ~/.wine'a dokunmaz)
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/lib.sh"
export WINEPREFIX="${WINEPREFIX:-$DIR/prefix}"
export WINEDEBUG=-all WINEDLLOVERRIDES="mscoree,mshtml=;winemenubuilder.exe=d"
APP="$WINEPREFIX/drive_c/Program Files/SmartPSSLite"
if [ ! -f "$APP/SmartPSSLite.exe" ]; then
  MSG="$(t "SmartPSS Lite is not installed. Run $DIR/setup.sh first." "SmartPSS Lite kurulu değil. Önce $DIR/setup.sh çalıştırın.")"
  echo "$MSG" >&2; command -v notify-send >/dev/null && notify-send "SmartPSS Lite" "$MSG"
  exit 1
fi
# The app's own dhMkDir cannot create nested directories under Wine; create them beforehand
# Uygulamanın kendi dhMkDir'i iç içe dizin açamıyor; önceden oluştur
U="$WINEPREFIX/drive_c/users/Public/SmartPSSLite"
mkdir -p "$U"/Conf/User/OrganizationBackup "$U"/Data/User/Database/{Log,LocalRes} \
  "$U"/Data/User/Picture/{Capture,AccessCapture,FacePictures,HumanTraitPictures,FaceGather,IvsPic} \
  "$U"/Data/User/Record "$U"/Log/{client_log,sdk_log}
cd "$APP" && exec wine SmartPSSLite.exe "$@"
