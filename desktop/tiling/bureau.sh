#!/bin/bash
# fedora-gaming — « Afficher le bureau » (Super+D, coin droit de la barre).
# Niri ne réduit pas les fenêtres : on bascule vers le bureau vide de l'écran
# (toujours présent en dernier), puis un second appui revient où l'on était.
etat="${XDG_RUNTIME_DIR:-/tmp}/niri-afficher-bureau"
ws=$(niri msg -j workspaces) || exit 1
cur=$(jq -c '.[] | select(.is_focused)' <<<"$ws")
sortie=$(jq -r '.output' <<<"$cur")
if [ "$(jq -r '.active_window_id' <<<"$cur")" = null ] && [ -s "$etat" ]; then
    niri msg action focus-workspace "$(cat "$etat")"
    rm -f "$etat"
else
    jq -r '.idx' <<<"$cur" > "$etat"
    vide=$(jq --arg o "$sortie" '[.[] | select(.output == $o) | .idx] | max' <<<"$ws")
    niri msg action focus-workspace "$vide"
fi
