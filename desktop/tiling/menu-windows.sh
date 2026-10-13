#!/bin/bash
# fedora-gaming — menu « Win+X » (aussi : clic droit sur Démarrer)
choix=$(printf '%s\n' \
    "   Paramètres" \
    "   Explorateur de fichiers" \
    "   Terminal" \
    "   Gestionnaire des tâches" \
    "   Son (mixeur)" \
    "   Réseau" \
    "   Logiciels (installer / mettre à jour)" \
    "   Verrouiller" \
    "   Se déconnecter" \
    "   Redémarrer" \
    "   Éteindre" |
    fuzzel --dmenu --prompt "" --placeholder "Menu rapide" --lines 11 --width 32 --no-icons \
        --font "Noto Sans:size=12,Font Awesome 6 Free:style=Solid:size=12")
case "$choix" in
    *Paramètres*)     exec systemsettings ;;
    *Explorateur*)    exec dolphin ;;
    *Terminal*)       exec konsole ;;
    *Gestionnaire*)   exec plasma-systemmonitor ;;
    *Son*)            exec pavucontrol ;;
    *Réseau*)         exec nm-connection-editor ;;
    *Logiciels*)      exec plasma-discover ;;
    *Verrouiller*)    exec swaylock -f ;;
    *déconnecter*)    exec niri msg action quit --skip-confirmation ;;
    *Redémarrer*)     exec systemctl reboot ;;
    *Éteindre*)       exec systemctl poweroff ;;
esac
