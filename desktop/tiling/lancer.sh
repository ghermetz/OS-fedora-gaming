#!/bin/bash
# fedora-gaming — applis épinglées de la barre : si l'appli est déjà ouverte,
# on affiche sa fenêtre ; sinon on la lance (comme les favoris de Zorin OS).
# Usage : lancer.sh <motif app-id> <commande…>
motif="$1"; shift
id=$(niri msg -j windows | jq -r --arg m "$motif" \
    '[.[] | select(.app_id // "" | test($m; "i"))] | sort_by(.is_focused) | last | .id // empty')
if [ -n "$id" ]; then exec niri msg action focus-window --id "$id"; fi
exec "$@"
