# Shared helpers (sourced by the other scripts). Messages are English; Turkish when the system language is Turkish.
# Paylaşılan yardımcılar. Mesajlar İngilizce; sistem dili Türkçeyse Türkçe.
case "${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}" in tr*) _TR=1 ;; *) _TR= ;; esac
# t "English" "Türkçe"
t() { if [ -n "$_TR" ]; then printf '%s' "$2"; else printf '%s' "$1"; fi; }
say() { printf '%s\n' "$(t "$1" "$2")"; }
err() { printf '%s %s\n' "$(t "ERROR:" "HATA:")" "$(t "$1" "$2")" >&2; exit 1; }
# ask "English" "Türkçe": accepts y/Y/e/E
ask() { read -r -p "$(t "$1" "$2") [y/N] " _a; [[ "$_a" =~ ^[yYeE]$ ]]; }
