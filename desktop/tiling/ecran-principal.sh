#!/bin/bash
# fedora-gaming — écran principal pour les applis X11 (Steam, jeux, Wine…).
# niri n'a pas d'écran « principal » ; X11 si, et c'est là que Steam, Wine et
# les jeux s'ouvrent. Par défaut : l'écran placé en haut à gauche (position 0,0).
# Pour en choisir un autre, écrire un bout de son nom (marque, modèle ou prise,
# comme affiché par « niri msg outputs ») dans ~/.config/fedora-gaming/ecran-principal
# — par exemple « AOC ». On le retrouve par son nom : ça marche même si on
# change les câbles de prise.
choix=$(grep -v '^#' ~/.config/fedora-gaming/ecran-principal 2>/dev/null | head -1)
prise=$(niri msg -j outputs | jq -r --arg c "$choix" '
    to_entries
    | (if $c != "" then map(select("\(.key) \(.value.make) \(.value.model)" | test($c; "i"))) else [] end) as $nommes
    | if ($nommes | length) > 0 then $nommes[0].key
      else (map(select(.value.logical.x == 0 and .value.logical.y == 0)) + .)[0].key end')
[ -n "$prise" ] && [ "$prise" != null ] || exit 1
# Déjà principal : rien à faire
xrandr --listmonitors 2>/dev/null | grep -q "\*$prise " && exit 0
xrandr --output "$prise" --primary
