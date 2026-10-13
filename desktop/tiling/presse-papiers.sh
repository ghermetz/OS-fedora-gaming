#!/bin/bash
# fedora-gaming — historique du presse-papiers (Super+V), comme sous Windows
if ! command -v cliphist >/dev/null; then
    notify-send -a "Presse-papiers" -i edit-paste "Historique indisponible" "Installez-le : sudo dnf install cliphist"
    exit 1
fi
choix=$(cliphist list | fuzzel --dmenu --prompt "📋  " --placeholder "Historique du presse-papiers…" --width 60) || exit
cliphist decode <<<"$choix" | wl-copy
