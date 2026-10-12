#!/usr/bin/env bash
# ============================================================================
#  fedora-gaming — desktop/firstrun/fedora-gaming-firstrun.sh
#  1re connexion après installation depuis l'ISO : propose de terminer la
#  configuration (codecs, Flatpaks, LACT, VS Code, Edge, WinBoat, Waydroid…)
#  en lançant install.sh. Rien en session live ; une seule fois par compte.
# ============================================================================
DONE="$HOME/.config/fedora-gaming/firstrun-done"
SHARE=/usr/share/fedora-gaming

[ -f "$DONE" ] && exit 0
[ "$USER" = "liveuser" ] && exit 0
[ -f /etc/sysconfig/livesys ] && grep -q '^livesys_session' /etc/sysconfig/livesys 2>/dev/null \
  && [ -d /run/initramfs/live ] && exit 0
mkdir -p "$(dirname "$DONE")"

if kdialog --title "Fedora Gaming" --yes-label "Terminer maintenant" --no-label "Plus tard" \
  --yesno "Bienvenue !

Le bureau est prêt. Pour finir, il reste à installer ce qui ne peut pas
être dans l'ISO (~20-40 min, connexion Internet nécessaire) :

  • codecs vidéo complets, pilotes VA-API, LACT (ventilos / OC de la carte)
  • Flatpaks : Heroic, Bottles, ProtonUp-Qt, Vesktop (Discord), Jellyfin
  • VS Code, Edge (Netflix), LibreOffice, Thunderbird, Distrobox, RetroArch
  • WinBoat (applis Windows), Waydroid (Android)

Ton mot de passe te sera demandé une fois."; then
  touch "$DONE"
  exec konsole --hold -p tabtitle="Fedora Gaming — fin de configuration" -e bash -c \
    "cd '$SHARE' && ASSUME_YES=1 bash install.sh --skip-desktop --skip-tiling; echo; echo 'Terminé — redémarre pour tout appliquer.'"
else
  kdialog --title "Fedora Gaming" --msgbox "Tu pourras le faire plus tard depuis le menu :
« Terminer la configuration Fedora Gaming »."
  touch "$DONE"
fi
