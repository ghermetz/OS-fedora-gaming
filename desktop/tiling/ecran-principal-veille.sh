#!/bin/bash
# fedora-gaming — garde l'écran principal des applis X11 (voir ecran-principal.sh).
# xwayland-satellite renvoie parfois la configuration des écrans (veille des
# écrans, changement de mode…) et l'écran principal est alors perdu : Wine
# (Naruto Online…) et les jeux s'ouvrent sur un autre écran, voire hors écran.
# On vérifie toutes les 3 s, seulement quand Xwayland tourne déjà (pour ne
# pas le démarrer inutilement).
while sleep 3; do
    pgrep -x Xwayland >/dev/null || continue
    ~/.config/fedora-gaming/ecran-principal.sh
done
