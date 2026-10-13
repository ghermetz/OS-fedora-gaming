#!/bin/bash
# fedora-gaming — manette affichée seulement quand GameMode est actif (jeu lancé)
if gamemoded -s 2>/dev/null | grep -q "is active"; then
    echo '{"text":"","class":"actif","tooltip":"GameMode actif : performances maximales pour le jeu en cours"}'
else
    echo '{"text":""}'
fi
