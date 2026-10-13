#!/bin/bash
# fedora-gaming — éclairage nocturne (moins de lumière bleue le soir), via wlsunset.
# « nuit.sh » bascule ; « nuit.sh etat » sert à l'icône de la barre.
if [ "$1" = etat ]; then
    if pgrep -x wlsunset >/dev/null; then
        echo '{"text":"","class":"actif","tooltip":"Éclairage nocturne : activé (20 h – 7 h)\nClic : désactiver"}'
    else
        echo '{"text":"","class":"inactif","tooltip":"Éclairage nocturne : désactivé\nClic : activer (20 h – 7 h)"}'
    fi
    exit
fi
if pkill -x wlsunset; then rm -f ~/.config/fedora-gaming/nuit-active
else touch ~/.config/fedora-gaming/nuit-active; setsid -f wlsunset -t 4000 -T 6500 -S 07:00 -s 20:00 >/dev/null 2>&1
fi
pkill -RTMIN+9 waybar
